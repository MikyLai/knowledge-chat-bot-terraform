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
  
  name                    = format("vnet-%s", var.resource_position_prefix)
  resource_group_name     = var.resource_group_name
  address_space           = var.address_spaces
  flow_timeout_in_minutes = var.flow_timeout_in_minutes
  location                = var.location
  dns_servers             = var.dns_servers
  bgp_community           = var.bgp_community
  edge_zone               = var.edge_zone
  tags                    = var.tags

  # dynamic "encryption" {
  #   for_each = var.enable_encryption_settings != null ? [1] : []
  #   content {
  #     enforcement = var.enable_encryption_settings
  #   }
  # }

  # dynamic "ddos_protection_plan" {
  #   for_each = local.ddos_pp_id != null ? [1] : []
  #   content {
  #     id     = local.ddos_pp_id
  #     enable = true
  #   }
  # }
}

##-----------------------------------------------------------------------------
## DDoS Plan – Creates a new plan if one is not provided
##-----------------------------------------------------------------------------
# resource "azurerm_network_ddos_protection_plan" "ddos_protection_plan" {
#   count               = local.create_ddos_plan ? 1 : 0 # Updated: Only create new DDOS Plan if existing one not provided
#   name                = var.resource_position_prefix ? format("ddospp-%s", local.name) : format("%s-ddospp", local.name)
#   location            = var.location
#   resource_group_name = var.resource_group_name
#   tags                = module.labels.tags

#   lifecycle {
#     prevent_destroy = false
#   }
# }

##-----------------------------------------------------------------------------
## Network Watcher – Enables Azure Network Watcher in the specified region if required.
## This is used primarily for enabling flow logs or diagnostics on NSGs.
## Azure automatically enables Network Watcher, but this allows specifying a custom name.
##-----------------------------------------------------------------------------
resource "azurerm_network_watcher" "flow_log_nw" {
  count               = var.enable && var.enable_network_watcher ? 1 : 0
  name                = format("nw-%s", var.resource_position_prefix) 
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}