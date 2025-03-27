# Masthead Data Dataplex agent

1. Enables required Google Cloud services: Pub/Sub, IAM, Logging.
2. Creates Pub/Sub topic and subscription.
3. Creates a custom IAM role for Dataplex locations.
4. Grants roles to the Masthead service account:

   - Pub/Sub Subscriber,
   - BigQuery Job User,
   - Dataplex DataScan Administrator,
   - Dataplex Storage Data Reader,
   - and custom Dataplex locations

5. Creates a log sink for Dataplex operations.
6. Grants Pub/Sub Publisher role to the Cloud Logging service account.
