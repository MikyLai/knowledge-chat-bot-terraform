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
    DATABASE_URL = "sqlite:////tmp/qr_code.db"
    WEBSITES_ENABLE_APP_SERVICE_STORAGE = "false"
    WEBSITES_PORT                  = tostring(var.container_port)
  }

  tags = local.tags
}