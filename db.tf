# create DB Instance
resource "azurerm_postgresql_flexible_server" "db" {
  name                   = "${var.app_name}-${var.environment}"
  resource_group_name    = azurerm_resource_group.app.name
  location               = azurerm_resource_group.app.location

  administrator_login    = "postgresadmin"
  administrator_password = var.db_password

  sku_name               = "B_Standard_B1ms"

  storage_mb             = 32768
  version                = "16"

  lifecycle {
    ignore_changes = [zone]
  }
}
# create database
resource "azurerm_postgresql_flexible_server_database" "qr_code_db" {
  collation = "en_US.utf8"
  charset   = "UTF8"
  name      = var.postgres_database_name
  server_id = azurerm_postgresql_flexible_server.db.id
}

# allow Azure services to access the server (for App Service VNet Integration)
resource "azurerm_postgresql_flexible_server_firewall_rule" "allow_azure" {
  name             = "allow-azure"
  server_id        = azurerm_postgresql_flexible_server.db.id

  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

resource "azurerm_postgresql_flexible_server_configuration" "log_statement" {
  name      = "log_statement"
  server_id = azurerm_postgresql_flexible_server.db.id
  value     = "all"
}