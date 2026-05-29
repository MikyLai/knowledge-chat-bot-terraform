variable "app_name" {
  type        = string
  description = "App Service Web App name (must be globally unique)"
  default     = "chat-bot"
}

variable "environment" {
  type        = string
  description = "Environment name (dev, prod)"
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group for Terraform state storage"
}

variable "subscription_id" {
  type        = string
  description = "Azure Subscription ID"
}