# create DB Instance
resource "azurerm_postgresql_flexible_server" "db" {
  name                   = "${var.app_name}-${var.environment}"
  resource_group_name    = var.app_resource_group_name
  location               = azurerm_resource_group.app.location

  administrator_login    = "postgresadmin"
  administrator_password = var.db_password

  sku_name               = "B_Standard_B1ms"

  storage_mb             = 32768
  version                = "16"

  # VNet injection – private access only, no public endpoint
  delegated_subnet_id           = module.network.db_subnet_id
  private_dns_zone_id           = azurerm_private_dns_zone.db.id
  public_network_access_enabled = false

  lifecycle {
    ignore_changes = [zone]
  }

  depends_on = [azurerm_private_dns_zone_virtual_network_link.db]
}
# create database
resource "azurerm_postgresql_flexible_server_database" "qr_code_db" {
  collation = "en_US.utf8"
  charset   = "UTF8"
  name      = var.postgres_database_name
  server_id = azurerm_postgresql_flexible_server.db.id
}


resource "azurerm_postgresql_flexible_server_configuration" "log_statement" {
  name      = "log_statement"
  server_id = azurerm_postgresql_flexible_server.db.id
  value     = "none"
}

##-----------------------------------------------------------------------------
## Private DNS Zone for PostgreSQL Flexible Server (VNet injection)
## For VNet-injected PostgreSQL Flexible Server, the private DNS zone is:
## <server-name>.private.postgres.database.azure.com
##-----------------------------------------------------------------------------
resource "azurerm_private_dns_zone" "db" {
  name                = "${var.app_name}-${var.environment}.private.postgres.database.azure.com"
  resource_group_name = var.app_resource_group_name

  tags = local.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "db" {
  name                  = "dns-link-db-${var.environment}"
  resource_group_name   = var.app_resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.db.name
  virtual_network_id    = module.network.vnet_id

  tags = local.tags
}