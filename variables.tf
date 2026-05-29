variable "app_name" {
  type        = string
  description = "App Service Web App name (must be globally unique)"
  default     = "chat-bot"
}

variable "app_resource_group_name" {
  type        = string
  description = "Resource group name for App Service resources"
}

variable "openai_api_key" {
    type        = string
    description = "API key for OpenAI"
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


variable "subscription_id" {
  type        = string
  description = "Azure Subscription ID"
}