##-----------------------------------------------------------------------------
## Subnet: App Service VNet Integration
## Delegates to Microsoft.Web/serverFarms so App Service can join the VNet
##-----------------------------------------------------------------------------
resource "azurerm_subnet" "app_service" {
  name                 = "snet-appservice-${var.environment}"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.app_service_subnet_cidr]

  delegation {
    name = "app-service-delegation"
    service_delegation {
      name    = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

##-----------------------------------------------------------------------------
## Subnet: PostgreSQL Flexible Server (private, no public access)
## Delegates to Microsoft.DBforPostgreSQL/flexibleServers
##-----------------------------------------------------------------------------
resource "azurerm_subnet" "db" {
  name                 = "snet-db-${var.environment}"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.db_subnet_cidr]

  delegation {
    name = "db-delegation"
    service_delegation {
      name    = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}

##-----------------------------------------------------------------------------
## VNet Integration: App Service → app_service subnet
## Routes App Service outbound traffic through the VNet,
## enabling it to reach private resources like DB in the same VNet
##-----------------------------------------------------------------------------
resource "azurerm_app_service_virtual_network_swift_connection" "app" {
  app_service_id = var.app_service_id
  subnet_id      = azurerm_subnet.app_service.id
}
