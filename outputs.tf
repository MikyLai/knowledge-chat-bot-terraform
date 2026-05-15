output "app_service_default_hostname" {
	value       = azurerm_linux_web_app.app.default_hostname
	description = "Default hostname of App Service"
}

output "app_service_url" {
	value       = "https://${azurerm_linux_web_app.app.default_hostname}"
	description = "Public URL of App Service"
}

output "Storage_connection_string" {
    value       = azurerm_storage_account.app.primary_connection_string
    description = "Connection string for Storage Account"
    sensitive = true
}