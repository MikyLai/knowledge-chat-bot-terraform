# -----------------------------------------------------------------------------
# Key Vault — stores sensitive secrets (e.g. OpenAI API Key)
# -----------------------------------------------------------------------------

data "azurerm_client_config" "current" {}

# User-Assigned Managed Identity — principal_id is known before web app is created
resource "azurerm_user_assigned_identity" "app" {
  name                = "id-${var.app_name}-${var.environment}"
  resource_group_name = var.app_resource_group_name
  location            = var.location
  tags                = local.tags
}

resource "azurerm_key_vault" "app" {
  name                     = "kv-${var.app_name}-${var.environment}-${random_string.suffix.result}"
  resource_group_name      = var.app_resource_group_name
  location                 = var.location
  tenant_id                = data.azurerm_client_config.current.tenant_id
  sku_name                 = "standard"
  purge_protection_enabled = false

  tags = local.tags
}

# Grant the deploying identity (CI/CD SP or local user) permission to write secrets
resource "azurerm_key_vault_access_policy" "deployer" {
  key_vault_id = azurerm_key_vault.app.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  secret_permissions = ["Get", "Set", "Delete", "List", "Purge", "Recover"]
}

# Grant App Service managed identity read-only access to secrets
resource "azurerm_key_vault_access_policy" "app" {
  key_vault_id = azurerm_key_vault.app.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_user_assigned_identity.app.principal_id

  secret_permissions = ["Get"]
}

resource "azurerm_key_vault_secret" "openai_api_key" {
  name         = "openai-api-key"
  value        = "placeholder"  # Set the real value manually after first apply
  key_vault_id = azurerm_key_vault.app.id

  depends_on = [azurerm_key_vault_access_policy.deployer]

  lifecycle {
    ignore_changes = [value]
  }
}
