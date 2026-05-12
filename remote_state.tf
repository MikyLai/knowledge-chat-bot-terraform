# -----------------------------------------------------------------------------
# Terraform Remote State — Storage Account & Container
# -----------------------------------------------------------------------------
resource "azurerm_resource_group" "tfstate" {
  name     = "rg-tfstate-qr"
  location = "eastasia"
}

resource "azurerm_storage_account" "tfstate" {
  name                     = "stqrtfstate038e436b"
  resource_group_name      = azurerm_resource_group.tfstate.name
  location                 = azurerm_resource_group.tfstate.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2" # default 值是 StorageV2，這裡明確指定以防未來變更預設
  min_tls_version          = "TLS1_2"

  # 禁止 public blob 存取
  allow_nested_items_to_be_public = false

  # 強制 HTTPS
  https_traffic_only_enabled = true

  blob_properties {
    versioning_enabled = true
  }

  tags = {
    project     = "qr-code-generator"
    environment = "shared"
    managedby   = "terraform"
  }
}

resource "azurerm_storage_container" "tfstate" {
  name                  = "tfstate"
  storage_account_name  = azurerm_storage_account.tfstate.name
  container_access_type = "private"
}
# LOCAL create then REMOTE state backend use tf init -migrate-state to migrate existing state to remote backend.
