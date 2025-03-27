# Masthead Data agent Terraform Module for Google Cloud

[![Open in Cloud Shell](https://gstatic.com/cloudssh/images/open-btn.svg)](https://shell.cloud.google.com/cloudshell/editor?cloudshell_git_repo=https%3A%2F%2Fgithub.com%2FMasthead-Data%2Fmasthead-deployment)

[![Terraform Module](https://img.shields.io/badge/Terraform-Module-blue.svg)](https://registry.terraform.io/modules/masthead-data/masthead-agent/google/latest)

## Overview

This repository contains Terraform module that deploys the resources for Masthead Data agent into Google Cloud.

## Usage

1. Ensure you have [Terraform installed](https://developer.hashicorp.com/terraform/install).
2. Configure your [gcloud CLI](https://cloud.google.com/sdk/gcloud#download_and_install_the) with your Google Cloud credentials.
3. Use Terraform module to deploy the infrastructure.

### Complete Deployment

Running a full deployment you will deploy the agent resources required for BigQuery, Dataform and Dataplex integration:

```bash
# Initialize Terraform configuration
terraform init

# Create an execution plan and save it to a file
terraform plan -out=tfplan

# Apply the planned changes to deploy the complete infrastructure
terraform apply tfplan
```

### Only BigQuery integration

The deployment can be limited to the resources required to integrate Masthead Data agent with BigQuery only:

```bash
terraform init
terraform plan -out=tfplan -target=module.bigquery
terraform apply tfplan
```

For step-by-step guide, refer to the [manual integration documentation](https://docs.mastheadata.com/saas-manual-resource-creation-google-cloud-+-bigquery).
