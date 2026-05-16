variable "app_resource_group_name" {
  type        = string
  description = "Resource group name for App Service resources"
}

variable "tenant_id" {
  type        = string
  description = "Azure Tenant ID"
  default     = "e611142c-7e66-410f-9240-bdbfbab3a8d0"
}

variable "environment" {
  type        = string
  description = "Environment name (dev, prod)"
}

variable "github_repository_name" {
  type        = string
  description = "Repository name for the App Service Web App (must be globally unique)"
  default     = "qr-code-generator-terraform"
}

variable "github_environments" {
  type = list(object({
    name                      = string
    requires_review_for_release = optional(bool, true)
  }))

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
  description = "Azure region"
  default     = "eastasia"
}

variable "project" {
  type        = string
  description = "Project name for tagging"
  default     = "qr-code-generator"
}

variable "subscription_id" {
  type        = string
  description = "Azure Subscription ID"
}


