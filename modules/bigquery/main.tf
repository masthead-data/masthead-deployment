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
  ack_deadline_seconds = 60
  expiration_policy {
    ttl = ""
  }
  message_retention_duration = "86400s"
  name                       = "masthead-agent-subscription"
  project                    = var.project_id
  topic                      = "projects/${var.project_id}/topics/masthead-topic"

  depends_on = [time_sleep.wait_30_seconds_to_create_topic]
}

#3. Create Log Sink.
resource "google_logging_project_sink" "masthead_sink" {
  depends_on = [google_pubsub_topic.masthead_topic,time_sleep.wait_30_seconds_to_enable_logging_service]
  name        = "masthead-agent-sink"
  description = "Masthead Agent log sink"
  destination = "pubsub.googleapis.com/projects/${var.project_id}/topics/masthead-topic"
  filter      = "protoPayload.methodName=\"google.cloud.bigquery.storage.v1.BigQueryWrite.AppendRows\" OR \"google.cloud.bigquery.v2.JobService.InsertJob\" OR \"google.cloud.bigquery.v2.TableService.InsertTable\" OR \"google.cloud.bigquery.v2.JobService.Query\" resource.type =\"bigquery_table\" OR resource.type =\"bigquery_dataset\" OR resource.type =\"bigquery_project\""
  project     = var.project_number
  unique_writer_identity = false
}

#4. Grant Cloud Logs default Service Account PubSub Publisher role.
resource "google_project_iam_member" "grant-cloud-logs-publisher-role" {
  project = var.project_id
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:service-${var.project_number}@gcp-sa-logging.iam.gserviceaccount.com"
}

#5. Grant Masthead service account required roles: BigQuery Metadata Viewer, BigQuery Resource Viewer, PubSub Subscriber.
resource "google_project_iam_member" "grant-masthead-data-roles" {
  for_each = toset(["roles/bigquery.metadataViewer", "roles/bigquery.resourceViewer", "roles/pubsub.subscriber"])

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:masthead-data@masthead-prod.iam.gserviceaccount.com"
}

#6. Grant Masthead service account required Private Log Viewer role.
resource "google_project_iam_member" "grant-masthead-retro-sa-privateLogViewer-role" {
  project = var.project_id
  role    = "roles/logging.privateLogViewer"
  member  = "serviceAccount:retro-data@masthead-prod.iam.gserviceaccount.com"
}
