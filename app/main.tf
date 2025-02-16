variable "project_id" {
  type        = string
  description = "The project id where to create resources. IAM & Admin -> Settings -> Project ID"
}

variable "project_number" {
  type        = string
  description = "The project number where to create resources. IAM & Admin -> Settings -> Project number"
}

provider "google" {
  project = var.project_id
}

#1. Enable required services in GCP
resource "google_project_service" "enable_pubsub_service" {
  project = var.project_id
  service = "pubsub.googleapis.com"

  disable_dependent_services = true
}

resource "google_project_service" "enable_iam_service" {
  project = var.project_id
  service = "iam.googleapis.com"

  disable_dependent_services = true
}

resource "google_project_service" "enable_logging_service" {
  project = var.project_id
  service = "logging.googleapis.com"

  disable_dependent_services = true
}

resource "time_sleep" "wait_30_seconds_to_enable_pubsub_service" {
  depends_on = [google_project_service.enable_pubsub_service]

  create_duration = "30s"
}

resource "time_sleep" "wait_30_seconds_to_enable_logging_service" {
  depends_on = [google_project_service.enable_logging_service]

  create_duration = "30s"
}

#2. Create Pub/Sub topic and subscription
resource "google_pubsub_topic" "masthead_topic" {
  name    = "masthead-topic"
  project = var.project_id
  depends_on = [time_sleep.wait_30_seconds_to_enable_pubsub_service]
}

resource "time_sleep" "wait_30_seconds_to_create_topic" {
  depends_on = [google_pubsub_topic.masthead_topic]

  create_duration = "30s"
}

resource "google_pubsub_subscription" "masthead_agent_subscription" {
  #TODO revise
  ack_deadline_seconds = 60
  expiration_policy {
    ttl = ""
  }
  #TODO revise
  message_retention_duration = "86400s"
  name                       = "masthead-agent-subscription"
  project                    = var.project_id
  topic                      = "projects/${var.project_id}/topics/masthead-topic"

  depends_on = [time_sleep.wait_30_seconds_to_create_topic]
}

#3. Create custom role with permissions
resource "google_project_iam_custom_role" "masthead_bq_schema_reader" {
  role_id     = "masthead_bq_schema_reader"
  title       = "masthead_bq_schema_reader"
  description = "Masthead schema structure reader"
  permissions = ["bigquery.datasets.get", "bigquery.routines.get", "bigquery.routines.list", "bigquery.tables.get", "bigquery.tables.list"]
}

#4. Grant Masthead SA required roles: PubSub subscriber, masthead_bq_schema_reader;
resource "google_project_iam_member" "grant-masthead-pubsub-subscriber-role" {
  project = var.project_id
  role    = "roles/pubsub.subscriber"
  member  = "serviceAccount:masthead-data@masthead-prod.iam.gserviceaccount.com"
}

resource "google_project_iam_member" "grant-masthead-custom-role" {
  project = var.project_id
  role    = "projects/${var.project_id}/roles/masthead_bq_schema_reader"
  member  = "serviceAccount:masthead-data@masthead-prod.iam.gserviceaccount.com"
}

#5. Create Log Sink. roles/pubsub.publisher will be assigned to default serviceAccount:cloud-logs@system.gserviceaccount.com
resource "google_logging_project_sink" "masthead_sink" {
  depends_on = [google_pubsub_topic.masthead_topic,time_sleep.wait_30_seconds_to_enable_logging_service]
  name        = "masthead-agent-sink"
  description = "Masthead Agent log sink"
  destination = "pubsub.googleapis.com/projects/${var.project_id}/topics/masthead-topic"
  filter      = "protoPayload.methodName=\"google.cloud.bigquery.storage.v1.BigQueryWrite.AppendRows\" OR \"google.cloud.bigquery.v2.JobService.InsertJob\" OR \"google.cloud.bigquery.v2.TableService.InsertTable\" OR \"google.cloud.bigquery.v2.JobService.Query\" resource.type =\"bigquery_table\" OR resource.type =\"bigquery_dataset\" OR resource.type =\"bigquery_project\""
  project     = var.project_number
  unique_writer_identity = false
}

#6. Grant cloud-logs SA PubSub Publisher role.
resource "google_project_iam_member" "grant-cloud-logs-publisher-role" {
  project = var.project_id
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:service-${var.project_number}@gcp-sa-logging.iam.gserviceaccount.com"
}

#7. Grant Retro SA with roles.
resource "google_project_iam_member" "grant-masthead-retro-sa-privateLogViewer-role" {
  project = var.project_id
  role    = "roles/logging.privateLogViewer"
  member  = "serviceAccount:retro-data@masthead-prod.iam.gserviceaccount.com"
}
