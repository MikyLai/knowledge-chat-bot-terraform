variable "app_name" {
  type        = string
  description = "App Service Web App name (must be globally unique)"
  default     = "app-qr-generator"
}

# variable "app_service_sku" {
#   type        = string
#   description = "App Service Plan SKU"
#   default     = "B1"
# }

variable "app_resource_group_name" {
  type        = string
  description = "Resource group name for App Service resources"
}

variable "db_password" {
    type        = string
    description = "Password for PostgreSQL admin user"
    sensitive   = true
}

variable "container_port" {
  type        = number
  description = "Container listening port"
  default     = 8000
}

variable "environment" {
  type        = string
  description = "Environment name (dev, prod)"
}

variable "ghcr_image" {
  type        = object({
    name    = string
    version = string
  })
  description = "Docker image in GHCR (e.g., ghcr.io/username/image)"
}

variable "location" {
  type        = string
  description = "Azure region"
  default     = "eastasia"
}

variable "postgres_database_name" {
    type        = string
    description = "Name of the PostgreSQL database"
    default     = "qr_code_db"
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