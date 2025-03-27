# Masthead Data BigQuery agent

1. Enables required Google Cloud services: Pub/Sub, IAM, Logging.
2. Creates Pub/Sub topic and subscription.
3. Grants Pub/Sub Publisher role to the Cloud Logging service account.
4. Creates a log sink for BigQuery operations.
5. Grants roles to the Masthead service account: Pub/Sub Subscriber, BigQuery Metadata Viewer, BigQuery Resource Viewer.
6. Grants a Private Logs Viewer role to the Masthead Retro service account.
