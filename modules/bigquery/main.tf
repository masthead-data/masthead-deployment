# BigQuery module - handles logging and IAM for BigQuery monitoring
# Note: Provider is configured at the root level

locals {
  resource_names = {
    topic        = "masthead-topic"
    subscription = "masthead-agent-subscription"
    sink         = "masthead-agent-sink"
  }

  # Merge default labels with user-provided labels
  common_labels = merge(var.labels, {
    component = "bigquery"
    service   = "masthead-agent"
  })
}

# Enable required Google Cloud APIs
resource "google_project_service" "required_apis" {
  for_each = toset([
    "pubsub.googleapis.com",
    "iam.googleapis.com",
    "logging.googleapis.com",
    "bigquery.googleapis.com"
  ])

  project = var.project_id
  service = each.value

  disable_on_destroy         = false
  disable_dependent_services = false
}

# Create Pub/Sub topic for BigQuery audit logs
resource "google_pubsub_topic" "masthead_topic" {
  depends_on = [google_project_service.required_apis]

  project = var.project_id
  name    = local.resource_names.topic

  labels = local.common_labels
}

# Create Pub/Sub subscription for the agent to consume messages
resource "google_pubsub_subscription" "masthead_agent_subscription" {
  project                    = var.project_id
  name                       = local.resource_names.subscription
  topic                      = google_pubsub_topic.masthead_topic.id
  message_retention_duration = "86400s" # 24 hours
  ack_deadline_seconds       = 60

  labels = local.common_labels

  # Prevent subscription from expiring
  expiration_policy {
    ttl = ""
  }
}

# Create logging sink to capture BigQuery audit logs
resource "google_logging_project_sink" "masthead_sink" {
  depends_on = [google_project_service.required_apis]

  project     = var.project_id
  name        = local.resource_names.sink
  description = "Masthead Agent log sink for BigQuery audit logs"
  destination = "pubsub.googleapis.com/${google_pubsub_topic.masthead_topic.id}"

  # Enhanced filter for comprehensive BigQuery monitoring
  filter = <<-EOT
    protoPayload.methodName="google.cloud.bigquery.storage.v1.BigQueryWrite.AppendRows" OR
    protoPayload.methodName="google.cloud.bigquery.v2.JobService.InsertJob" OR
    protoPayload.methodName="google.cloud.bigquery.v2.TableService.InsertTable" OR
    protoPayload.methodName="google.cloud.bigquery.v2.JobService.Query"
    resource.type="bigquery_table" OR
    resource.type="bigquery_dataset" OR
    resource.type="bigquery_project"
  EOT

  unique_writer_identity = true
}

# Grant Cloud Logging service account permission to publish to Pub/Sub topic
resource "google_pubsub_topic_iam_member" "logging_pubsub_publisher" {
  project = var.project_id
  topic   = google_pubsub_topic.masthead_topic.name
  role    = "roles/pubsub.publisher"
  member  = google_logging_project_sink.masthead_sink.writer_identity
}

# Grant Masthead service account subscriber permission on the subscription
resource "google_pubsub_subscription_iam_member" "masthead_subscription_subscriber" {
  project      = var.project_id
  subscription = google_pubsub_subscription.masthead_agent_subscription.name
  role         = "roles/pubsub.subscriber"
  member       = "serviceAccount:${var.masthead_service_accounts.bigquery_sa}"
}

# Grant Masthead service account required roles
resource "google_project_iam_member" "masthead_bigquery_roles" {
  for_each = toset([
    "roles/bigquery.metadataViewer",
    "roles/bigquery.resourceViewer"
  ])

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${var.masthead_service_accounts.bigquery_sa}"
}

# Grant Masthead retro service account Private Log Viewer role (optional)
resource "google_project_iam_member" "masthead_privatelogviewer_role" {
  count = var.enable_privatelogviewer_role ? 1 : 0

  project = var.project_id
  role    = "roles/logging.privateLogViewer"
  member  = "serviceAccount:${var.masthead_service_accounts.retro_sa}"
}
