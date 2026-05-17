terraform {
  required_version = ">= 1.7.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.110"
    }

    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }

    external = {
      source  = "hashicorp/external"
      version = "~> 2.3"
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 3.8"
    }
  }

  # Run bootstrap/create-remote-state.sh once to provision this backend.
  # Then replace the placeholder values below with the actual output.
  backend "azurerm" {
    resource_group_name  = "rg-tfstate-qr"
    storage_account_name = "stqrtfstate038e436b"
    container_name       = "tfstate"
    key                  = "bootstrapping.tfstate"
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

provider "azuread" {}

provider "github" {
  owner = "MikyLai"
  # token 從環境變數 GITHUB_TOKEN 自動讀取，不需要寫在程式碼裡
}



resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

data "azurerm_subscription" "current" {
}

locals {
  tags = {
    project     = var.project
    environment = var.environment
    managedby   = "terraform"
  }
  resource_suffix = "${var.environment}-${random_string.suffix.result}"
  subscription_id = data.azurerm_subscription.current.subscription_id
}




