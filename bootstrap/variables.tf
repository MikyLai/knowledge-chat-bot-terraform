variable "app_resource_group_name" {
  type        = string
  description = "Resource group name for App Service resources"
}

variable "tenant_id" {
  type        = string
  description = "Azure Tenant ID"
  default     = "e611142c-7e66-410f-9240-bdbfbab3a8d0"
}

# output resource_group_name from remote-state
variable "tfstate_resource_group_name" {
  type        = string
  description = "Resource group name for Terraform state storage"
  default     = "rg-tfstate-chat-bot-dev"
}

# output storage_account_name from remote-state
variable "tfstate_storage_account_name" {
  type        = string
  description = "Storage account name for Terraform state"
  default     = "stqrtfstatebj78mn"
}

variable "environment" {
  type        = string
  description = "Environment name (dev, prod)"
}

variable "github_repository_name" {
  type        = string
  description = "Repository name for the App Service Web App (must be globally unique)"
  default     = "knowledge-chat-bot-terraform"
}

variable "github_environments" {
  type = list(object({
    name                      = string
    requires_review_for_release = optional(bool, true)
  }))
  default = [
  {
    name = "dev"
    requires_review_for_release = false
  },
  {
    name = "prod"
  }
]

  validation {
    condition     = alltrue([for e in var.github_environments : e.name == lower(e.name)])
    error_message = "All environment names must be lowercase."
  }

  description = <<EOF
GitHub environment names. Must be lowercase and unique per repository.
requires_review_for_release defaults to true except for dev / non-prod environments.
EOF
}
variable "location" {
  type        = string
  description = "Azure region for all resources"
  default     = "eastasia"
}

variable "subscription_id" {
  type        = string
  description = "Azure Subscription ID"
}


