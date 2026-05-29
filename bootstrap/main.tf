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

  # Replace the resource_group_name and storage_account_name values below with the actual output from remote-state.

  backend "azurerm" {
    resource_group_name  = "rg-tfstate-chat-bot-dev" 
    storage_account_name = "tfstatebj78mn"
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

resource "azurerm_resource_group" "app" {
  name     = var.app_resource_group_name
  location = var.location

  tags = local.tags
}

locals {
  tags = {
    environment = var.environment
    managedby   = "terraform"
  }
}




