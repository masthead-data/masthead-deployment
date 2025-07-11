variable "project_id" {
  type        = string
  description = "The GCP project ID where resources will be created"
}

variable "masthead_service_accounts" {
  type = object({
    bigquery_sa = string
    dataform_sa = string
    dataplex_sa = string
    retro_sa    = string
  })
  description = "Masthead service account emails for different services"
}

variable "enable_privatelogviewer_role" {
  type        = bool
  description = "Enable privateLogViewer role for Masthead service account"
  default     = true
}

variable "labels" {
  type        = map(string)
  description = "Labels to apply to all resources"
  default     = {}
}
