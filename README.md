# Masthead Data Agent Terraform Module for Google Cloud

[![Terraform Module](https://img.shields.io/badge/Terraform-Module-blue.svg)](https://registry.terraform.io/modules/masthead-data/masthead-agent/google/latest)

This Terraform module deploys the infrastructure required for Masthead Data agents to monitor Google Cloud services including BigQuery, Dataform, Dataplex, and Analytics Hub.

## Architecture

The module creates monitoring infrastructure for each enabled service:

- **API Enablement**: Required Google Cloud APIs
- **Pub/Sub Topics & Subscriptions**: For reliable log message delivery
- **Cloud Logging Sinks**: To route audit logs to Pub/Sub
- **IAM Bindings**: Secure access for Masthead service accounts

## Quick Start

### Prerequisites

1. [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.5.7
2. [Google Cloud CLI](https://cloud.google.com/sdk/gcloud) configured with authentication
3. GCP project with appropriate permissions

### Basic Usage

```hcl
module "masthead_agent" {
  source  = "masthead-data/masthead-agent/google"

  project_id = "YOUR_PROJECT_ID"
}
```

### Advanced Configuration

```hcl
module "masthead_agent" {
  source  = "masthead-data/masthead-agent/google"

  project_id = "YOUR_PROJECT_ID"

  # Enable only specific modules
  enable_modules = {
    bigquery      = true
    dataform      = true
    dataplex      = true
    analytics_hub = true
  }

  # Enable Private Log Viewer role for Masthead service account
  enable_privatelogviewer_role = true

  # Custom labels for resource management
  labels = {
    environment = "production"
    team        = "data"
    cost_center = "engineering"
  }
}
```

## Deployment Options

### Complete Deployment (All Services)

```bash
# Copy and customize the example variables file
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your project_id and preferences

# Initialize and apply
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

### BigQuery Only

```bash
terraform init
terraform plan -out=tfplan \
  -var="project_id=YOUR_PROJECT_ID" \
  -var='enable_modules={"bigquery"=true,"dataform"=false,"dataplex"=false,"analytics_hub"=false}'
terraform apply tfplan
```

### Using Google Cloud Shell

[![Open in Google Cloud Shell](https://gstatic.com/cloudssh/images/open-btn.svg)](https://shell.cloud.google.com/cloudshell/editor?cloudshell_git_repo=https%3A%2F%2Fgithub.com%2FMasthead-Data%2Fterraform-google-masthead-agent)

## Input Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `project_id` | The GCP project ID where resources will be created | `string` | n/a | yes |
| `enable_modules` | Enable/disable specific modules | `object` | All enabled | no |
| `masthead_service_accounts` | Masthead service account emails | `object` | Masthead defaults | no |
| `enable_privatelogviewer_role` | Enable Private Log Viewer role for Masthead service account | `bool` | `true` | no |
| `labels` | Labels to apply to all resources | `map(string)` | Default labels | no |

### Enable Modules Structure

```hcl
enable_modules = {
  bigquery      = bool  # Enable BigQuery monitoring
  dataform      = bool  # Enable Dataform monitoring
  dataplex      = bool  # Enable Dataplex monitoring
  analytics_hub = bool  # Enable Analytics Hub monitoring
}
```

### Service Accounts Structure

```hcl
masthead_service_accounts = {
  bigquery_sa  = string  # BigQuery monitoring service account
  dataform_sa  = string  # Dataform monitoring service account
  dataplex_sa  = string  # Dataplex monitoring service account
  retro_sa     = string  # Retro analysis service account
}
```

## Outputs

| Name | Description |
|------|-------------|
| `bigquery` | BigQuery module outputs (topics, subscriptions, sinks) |
| `dataform` | Dataform module outputs (topics, subscriptions, sinks) |
| `dataplex` | Dataplex module outputs (topics, subscriptions, sinks) |
| `analytics_hub` | Analytics Hub module outputs (IAM bindings) |
| `enabled_modules` | List of enabled modules |
| `project_id` | The GCP project ID where resources were created |

## Security Features

- **Unique Writer Identities**: Each logging sink uses its own service account
- **Least Privilege Access**: Minimal required permissions for each service account

## Module Structure

```text
modules/
├── analytics-hub/    # Analytics Hub IAM permissions
├── bigquery/         # BigQuery logging and monitoring
├── dataform/         # Dataform logging and monitoring
└── dataplex/         # Dataplex logging and monitoring
```

Each module includes:

- `main.tf` - Resource definitions
- `variables.tf` - Input variables
- `outputs.tf` - Output values
- `versions.tf` - Provider requirements
- `README.md` - Module documentation

## Requirements

- **Terraform**: >= 1.5.7
- **Google Provider**: >= 6.13.0
- **GCP APIs**: Automatically enabled by the module
- **IAM Permissions**: Project Owner or equivalent custom role

## Contributing

Contributions are welcome! Please ensure:

1. All modules follow the same structure and conventions
2. Variables include proper validation where applicable
3. Resources are properly labeled and documented
4. README files are updated for any changes

## License

This module is released under Apache-2.0 license. See [LICENSE](LICENSE) for details.

## References

- [Masthead Data Documentation](https://docs.mastheadata.com/saas-manual-resource-creation-google-cloud-+-bigquery)
- [Module in Terraform Registry](https://registry.terraform.io/modules/masthead-data/masthead-agent/google/latest)

---

For support, please refer to the [Masthead Data documentation](https://docs.mastheadata.com) or contact your Masthead Data representative.
