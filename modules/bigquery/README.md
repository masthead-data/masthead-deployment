# BigQuery Module

This module sets up the necessary infrastructure for Masthead Data to monitor BigQuery operations in your Google Cloud project.

## Resources Created

- **Pub/Sub Topic**: Receives BigQuery audit logs
- **Pub/Sub Subscription**: Allows Masthead agents to consume audit logs
- **Cloud Logging Sink**: Routes BigQuery audit logs to Pub/Sub
- **IAM Bindings**: Grants necessary permissions to Masthead service accounts

## APIs Enabled

- `pubsub.googleapis.com`
- `iam.googleapis.com`
- `logging.googleapis.com`
- `bigquery.googleapis.com`

## Required Variables

- `project_id`: Your GCP project ID
- `masthead_service_accounts`: Object containing Masthead service account emails

## Optional Variables

- `enable_privatelogviewer_role`: Enable Private Log Viewer role for Masthead service account (default: true)
- `labels`: Labels to apply to all resources

## Outputs

- `pubsub_topic_id`: ID of the created Pub/Sub topic
- `pubsub_subscription_id`: ID of the created subscription
- `logging_sink_id`: ID of the logging sink
- `logging_sink_writer_identity`: Writer identity for the logging sink
