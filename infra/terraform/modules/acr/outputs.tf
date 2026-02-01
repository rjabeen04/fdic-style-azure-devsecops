output "id" {
  description = "ACR resource ID"
  value       = azurerm_container_registry.this.id
}

output "name" {
  description = "ACR name"
  value       = azurerm_container_registry.this.name
}

output "login_server" {
  description = "ACR login server (e.g., myacr.azurecr.io)"
  value       = azurerm_container_registry.this.login_server
}

output "resource_group_name" {
  description = "ACR resource group name"
  value       = azurerm_container_registry.this.resource_group_name
}
