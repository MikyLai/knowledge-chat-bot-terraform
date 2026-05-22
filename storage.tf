resource "azurerm_storage_account" "app" {
  name                     = "qrgenerator${replace(local.resource_suffix, "-", "")}"
  resource_group_name      = azurerm_resource_group.app.name
  location                 = azurerm_resource_group.app.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2" # default 值是 StorageV2，這裡明確指定以防未來變更預設
  min_tls_version          = "TLS1_2"

  # QR images served via SAS URLs; public network access required so browsers can fetch images
  allow_nested_items_to_be_public = false

  # 強制 HTTPS
  https_traffic_only_enabled = true

  blob_properties {
    versioning_enabled = true
  }

  tags = local.tags
}

resource "azurerm_storage_container" "app" {
  name                  = "qr-code"
  storage_account_name  = azurerm_storage_account.app.name
  container_access_type = "private"
}