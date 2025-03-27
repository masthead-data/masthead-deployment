# Masthead Data Dataform agent

1. Enables required Google Cloud services: Pub/Sub, IAM, Logging.
2. Creates Pub/Sub topic and subscription.
3. Grants Pub/Sub Subscriber and Dataform Viewer roles to the Masthead service account.
4. Creates a log sink for Dataform operations.
5. Grants Pub/Sub Publisher role to the Cloud Logging service account.
