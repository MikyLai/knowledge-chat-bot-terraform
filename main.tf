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

  # Run bootstrap/create-remote-state.sh once to provision this backend.
  # Then replace the placeholder values below with the actual output.
  backend "azurerm" {
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

resource "azurerm_resource_group" "app" {
  name     = var.app_resource_group_name
  location = var.location

  tags = local.tags
}

module "network" {
  source = "./module/network"

  address_spaces          = ["10.0.0.0/16"]
  app_name                = var.app_name
  app_service_subnet_cidr  = "10.0.1.0/24"
  db_subnet_cidr           = "10.0.2.0/24"
  enable_network_watcher  = true
  environment             = var.environment
  location                = var.location
  resource_group_name     = azurerm_resource_group.app.name
  tags                    = local.tags
}

