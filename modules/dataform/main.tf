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
resource "google_pubsub_topic" "masthead_dataform_topic" {
  name    = "masthead-dataform-topic"
  project = var.project_id
  depends_on = [time_sleep.wait_30_seconds_to_enable_pubsub_service]
}

resource "time_sleep" "wait_30_seconds_to_create_topic" {
  depends_on = [google_pubsub_topic.masthead_dataform_topic]

  create_duration = "30s"
}

resource "google_pubsub_subscription" "masthead_dataform_subscription" {
  ack_deadline_seconds = 60
  expiration_policy {
    ttl = ""
  }
  message_retention_duration = "86400s"
  name                       = "masthead-dataform-subscription"
  project                    = var.project_id
  topic                      = "projects/${var.project_id}/topics/masthead-dataform-topic"

  depends_on = [time_sleep.wait_30_seconds_to_create_topic]
}

#3. Grant Masthead SA required roles: pubsub.subscriber, dataform.viewer
resource "google_project_iam_member" "masthead-dataform-pubsub-subscriber-role" {
  project = var.project_id
  role    = "roles/pubsub.subscriber"
  member  = "serviceAccount:masthead-dataform@masthead-prod.iam.gserviceaccount.com"
}

resource "google_project_iam_member" "masthead-dataplex-bigquery-jobUser-role" {
  project = var.project_id
  role    = "roles/dataform.viewer"
  member  = "serviceAccount:masthead-dataform@masthead-prod.iam.gserviceaccount.com"
}

#4. Create Log Sink.
resource "google_logging_project_sink" "masthead_dataplex_sink" {
  depends_on = [google_pubsub_topic.masthead_dataform_topic,time_sleep.wait_30_seconds_to_enable_logging_service]
  description = "Masthead Dataform log sink"
  destination = "pubsub.googleapis.com/projects/${var.project_id}/topics/masthead-dataform-topic"
  filter      = "protoPayload.serviceName=\"dataform.googleapis.com\" OR resource.type=\"dataform.googleapis.com/Repository\""
  name        = "masthead-dataform-sink"
  project     = var.project_number
  unique_writer_identity = false
}

#5. Grant cloud-logs SA PubSub Publisher role.
resource "google_project_iam_member" "grant-cloud-logs-publisher-role" {
  project = var.project_id
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:service-${var.project_number}@gcp-sa-logging.iam.gserviceaccount.com"
}
