output "app_service_default_hostname" {
	value       = azurerm_linux_web_app.app.default_hostname
	description = "Default hostname of App Service"
}

output "app_service_url" {
	value       = "https://${azurerm_linux_web_app.app.default_hostname}"
	description = "Public URL of App Service"
}