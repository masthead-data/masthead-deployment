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
resource "google_pubsub_topic" "masthead_dataplex_topic" {
  name    = "masthead-dataplex-topic"
  project = var.project_id
  depends_on = [time_sleep.wait_30_seconds_to_enable_pubsub_service]
}

resource "time_sleep" "wait_30_seconds_to_create_topic" {
  depends_on = [google_pubsub_topic.masthead_dataplex_topic]

  create_duration = "30s"
}

resource "google_pubsub_subscription" "masthead_dataplex_subscription" {
  ack_deadline_seconds = 60
  expiration_policy {
    ttl = ""
  }
  message_retention_duration = "86400s"
  name                       = "masthead-dataplex-subscription"
  project                    = var.project_id
  topic                      = "projects/${var.project_id}/topics/masthead-dataplex-topic"

  depends_on = [time_sleep.wait_30_seconds_to_create_topic]
}

#3. Create custom role for Dataplex locations
resource "google_project_iam_custom_role" "masthead_dataplex_locations" {
  role_id     = "masthead_dataplex_locations"
  title       = "masthead_dataplex_locations"
  description = "Masthead DataPlex locations reader"
  permissions = ["dataplex.locations.get", "dataplex.locations.list"]
}

#4. Grant Masthead SA required roles: pubsub.subscriber, bigquery.jobUser, dataplex.dataScanAdmin, dataplex.storageDataReader, masthead_dataplex_locations;
resource "google_project_iam_member" "masthead-dataplex-pubsub-subscriber-role" {
  project = var.project_id
  role    = "roles/pubsub.subscriber"
  member  = "serviceAccount:masthead-dataplex@masthead-prod.iam.gserviceaccount.com"
}

resource "google_project_iam_member" "masthead-dataplex-bigquery-jobUser-role" {
  project = var.project_id
  role    = "roles/bigquery.jobUser"
  member  = "serviceAccount:masthead-dataplex@masthead-prod.iam.gserviceaccount.com"
}

resource "google_project_iam_member" "masthead-dataplex-dataplex-dataScanAdmin-role" {
  project = var.project_id
  role    = "roles/dataplex.dataScanAdmin"
  member  = "serviceAccount:masthead-dataplex@masthead-prod.iam.gserviceaccount.com"
}

resource "google_project_iam_member" "masthead-dataplex-dataplex-storageDataReader-role" {
  project = var.project_id
  role    = "roles/dataplex.storageDataReader"
  member  = "serviceAccount:masthead-dataplex@masthead-prod.iam.gserviceaccount.com"
}

resource "google_project_iam_member" "masthead-dataplex-dataplex-locations-role" {
  project = var.project_id
  role    = "projects/${var.project_id}/roles/masthead_dataplex_locations"
  member  = "serviceAccount:masthead-dataplex@masthead-prod.iam.gserviceaccount.com"
}

#5. Create Log Sink. roles/pubsub.publisher will be assigned to default serviceAccount:cloud-logs@system.gserviceaccount.com
resource "google_logging_project_sink" "masthead_dataplex_sink" {
  depends_on = [google_pubsub_topic.masthead_dataplex_topic,time_sleep.wait_30_seconds_to_enable_logging_service]
  description = "Masthead Dataplex log sink"
  destination = "pubsub.googleapis.com/projects/${var.project_id}/topics/masthead-dataplex-topic"
  filter      = "jsonPayload.@type=\"type.googleapis.com/google.cloud.dataplex.v1.DataScanEvent\" OR protoPayload.methodName=\"google.cloud.dataplex.v1.DataScanService.CreateDataScan\" OR protoPayload.methodName=\"google.cloud.dataplex.v1.DataScanService.UpdateDataScan\" OR protoPayload.methodName=\"google.cloud.dataplex.v1.DataScanService.DeleteDataScan\" AND (severity=\"INFO\" OR \"NOTICE\")"
  name        = "masthead-dataplex-sink"
  project     = var.project_number
  unique_writer_identity = false
}

#6. Grant cloud-logs SA PubSub Publisher role.
resource "google_project_iam_member" "grant-cloud-logs-publisher-role" {
  project = var.project_id
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:service-${var.project_number}@gcp-sa-logging.iam.gserviceaccount.com"
}
