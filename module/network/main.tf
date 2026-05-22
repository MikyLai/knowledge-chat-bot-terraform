terraform {
  required_version = ">= 1.7.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.110"
    }
  
  }

}

resource "azurerm_virtual_network" "vnet" {
  
  name                    = "vnet-${var.app_name}-${var.environment}"
  resource_group_name     = var.resource_group_name
  address_space           = var.address_spaces
  flow_timeout_in_minutes = var.flow_timeout_in_minutes
  location                = var.location
  dns_servers             = var.dns_servers
  bgp_community           = var.bgp_community
  edge_zone               = var.edge_zone
  tags                    = var.tags

}

##-----------------------------------------------------------------------------
## Network Watcher – Enables Azure Network Watcher in the specified region if required.
## This is used primarily for enabling flow logs or diagnostics on NSGs.
## Azure automatically enables Network Watcher, but this allows specifying a custom name.
##-----------------------------------------------------------------------------
resource "azurerm_network_watcher" "flow_log_nw" {
  count               = var.enable_network_watcher ? 1 : 0
  name                = "nw-${var.app_name}-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}