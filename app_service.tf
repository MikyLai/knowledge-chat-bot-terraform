# -----------------------------------------------------------------------------
# Public Site (No VNet)
# App Service pulls Docker image from GHCR
# -----------------------------------------------------------------------------

resource "azurerm_service_plan" "app" {
  name                = "asp-qr-${var.environment}"
  resource_group_name = azurerm_resource_group.app.name
  location            = azurerm_resource_group.app.location
  os_type             = "Linux"
  sku_name            = "B1"

  tags = local.tags
}

# locals {
#   ghcr_username = var.ghcr_username != "" ? var.ghcr_username : null
#   ghcr_token    = var.ghcr_token != "" ? var.ghcr_token : null
# }

resource "azurerm_linux_web_app" "app" {
  name                = var.app_name
  resource_group_name = azurerm_resource_group.app.name
  location            = azurerm_resource_group.app.location
  service_plan_id     = azurerm_service_plan.app.id
  https_only          = true

  site_config {
    always_on = false

    application_stack {
      docker_image_name        = "${var.ghcr_image.name}:${var.ghcr_image.version}"
      docker_registry_url      = "https://ghcr.io"
      # docker_registry_username = local.ghcr_username
      # docker_registry_password = local.ghcr_token
    }
  }

  app_settings = {
    AZURE_BLOB_CONTAINER= azurerm_storage_container.app.name
    AZURE_STORAGE_CONNECTION_STRING = azurerm_storage_account.app.primary_connection_string
    BASE_URL = "https://${var.app_name}.azurewebsites.net"
    BLOB_PUBLIC_HOST= "${azurerm_storage_account.app.name}.blob.core.windows.net"
    # db.fqdn resolves to "app-qr-generator-dev.postgres.database.azure.com" (no .private. in the hostname).
    # From inside the VNet, Azure split-horizon DNS intercepts this query and follows a CNAME chain:
    #   app-qr-generator-dev.postgres.database.azure.com
    #     → CNAME → <uid>.app-qr-generator-dev.private.postgres.database.azure.com
    #     → Private DNS Zone A record → 10.0.2.x (private IP, never leaves VNet)
    # Direct use of the .private. hostname does NOT work (no A record at that exact name).
    DATABASE_URL = sensitive("postgresql+psycopg://postgresadmin:${urlencode(var.DB_PASSWORD)}@${azurerm_postgresql_flexible_server.db.fqdn}:5432/${var.postgres_database_name}?sslmode=require")
    WEBSITES_ENABLE_APP_SERVICE_STORAGE = "false"
    WEBSITES_PORT                  = tostring(var.container_port)
  }

  tags = local.tags

  lifecycle {
    ignore_changes = [
      auth_settings,
      auth_settings_v2,
      # managed by azurerm_app_service_virtual_network_swift_connection in module.network
      virtual_network_subnet_id,
    ]
  }
}