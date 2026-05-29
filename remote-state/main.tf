# -----------------------------------------------------------------------------
# Terraform Remote State — Storage Account & Container
# Managed separately with LOCAL state (no backend block).
# Run once: terraform init && terraform import ...
# -----------------------------------------------------------------------------
terraform {
  required_version = ">= 1.7.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.110"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

resource "azurerm_resource_group" "tfstate" {
  name     = var.resource_group_name
  location = "eastasia"
}


resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

resource "azurerm_storage_account" "tfstate" {
  name                     = "stqrtfstate${random_string.suffix.result}"
  resource_group_name      = azurerm_resource_group.tfstate.name
  location                 = azurerm_resource_group.tfstate.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2" # default 值是 StorageV2，這裡明確指定以防未來變更預設
  min_tls_version          = "TLS1_2"

  # 禁止 public blob 存取
  allow_nested_items_to_be_public = false

  # 強制 HTTPS
  https_traffic_only_enabled = true

  blob_properties {
    versioning_enabled = true
  }

  tags = local.tags
}

resource "azurerm_storage_container" "tfstate" {
  name                  = "tfstate"
  storage_account_name  = azurerm_storage_account.tfstate.name
  container_access_type = "private"
}
# LOCAL create then REMOTE state backend use tf init -migrate-state to migrate existing state to remote backend.
