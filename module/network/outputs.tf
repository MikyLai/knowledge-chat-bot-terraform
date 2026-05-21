output "vnet_id" {
  description = "Resource ID of the virtual network."
  value       = azurerm_virtual_network.vnet.id
}

output "db_subnet_id" {
  description = "Resource ID of the PostgreSQL Flexible Server subnet."
  value       = azurerm_subnet.db.id
}

output "app_service_subnet_id" {
  description = "Resource ID of the App Service VNet integration subnet."
  value       = azurerm_subnet.app_service.id
}
