output "resource_group_name" {
  value       = azurerm_resource_group.tfstate.name
  description = "Name of the resource group for bootstrap backend"
}

output "storage_account_name" {
  value       = azurerm_storage_account.tfstate.name
  description = "Name of the storage account for bootstrap backend"
}