# -----------------------------------------------------------------------------
# Public Site (No VNet)
# App Service pulls Docker image from GHCR
# -----------------------------------------------------------------------------

resource "azurerm_service_plan" "app" {
  name                = "asp-${var.app_name}${var.environment}"
  resource_group_name = var.app_resource_group_name
  location            = var.location
  os_type             = "Linux"
  sku_name            = "B1"

  tags = local.tags
}

# locals {
#   ghcr_username = var.ghcr_username != "" ? var.ghcr_username : null
#   ghcr_token    = var.ghcr_token != "" ? var.ghcr_token : null
# }

resource "azurerm_linux_web_app" "app" {
  name                = "${var.app_name}-${var.environment}"
  resource_group_name = var.app_resource_group_name
  location            = var.location
  service_plan_id     = azurerm_service_plan.app.id
  https_only          = true

  site_config {
    always_on         = false
    health_check_path = "/health"

    application_stack {
      docker_image_name        = "${var.ghcr_image.name}:${var.ghcr_image.version}"
      docker_registry_url      = "https://ghcr.io"
      # docker_registry_username = local.ghcr_username
      # docker_registry_password = local.ghcr_token
    }
  }

  app_settings = {
    OPENAI_API_KEY             = var.openai_api_key
    WEBSITES_PORT                  = tostring(var.container_port)
  }

  tags = local.tags

  lifecycle {
    ignore_changes = [
      auth_settings,
      auth_settings_v2,
      # managed by azurerm_app_service_virtual_network_swift_connection below
      virtual_network_subnet_id,
    ]
  }
}
