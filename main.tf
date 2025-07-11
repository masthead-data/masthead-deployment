terraform {
  required_version = ">= 1.5.7"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 6.13.0"
    }
  }
}

module "bigquery" {
  count  = var.enable_modules.bigquery ? 1 : 0
  source = "./modules/bigquery"

  project_id                   = var.project_id
  masthead_service_accounts    = var.masthead_service_accounts
  enable_privatelogviewer_role = var.enable_privatelogviewer_role
  labels                       = var.labels
}

module "dataform" {
  count  = var.enable_modules.dataform ? 1 : 0
  source = "./modules/dataform"

  project_id                = var.project_id
  masthead_service_accounts = var.masthead_service_accounts
  labels                    = var.labels
}

module "dataplex" {
  count  = var.enable_modules.dataplex ? 1 : 0
  source = "./modules/dataplex"

  project_id                = var.project_id
  masthead_service_accounts = var.masthead_service_accounts
  labels                    = var.labels
}

module "analytics_hub" {
  count  = var.enable_modules.analytics_hub ? 1 : 0
  source = "./modules/analytics-hub"

  project_id                = var.project_id
  masthead_service_accounts = var.masthead_service_accounts
  labels                    = var.labels
}
