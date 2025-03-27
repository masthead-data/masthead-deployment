terraform {
  required_version = ">= 1.9.7"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 6.13.0"
    }
  }
}

module "bigquery" {
  source = "./modules/bigquery"

  project_id     = var.project_id
  project_number = var.project_number
}

module "dataform" {
  source = "./modules/dataform"

  project_id     = var.project_id
  project_number = var.project_number
}

module "dataplex" {
  source = "./modules/dataplex"

  project_id     = var.project_id
  project_number = var.project_number
}
