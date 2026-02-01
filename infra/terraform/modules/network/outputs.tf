output "vnet_id" {
  description = "VNet resource ID."
  value       = azurerm_virtual_network.this.id
}

output "vnet_name" {
  description = "VNet name."
  value       = azurerm_virtual_network.this.name
}

output "subnet_ids" {
  description = "Map of subnet IDs by subnet name."
  value       = { for k, s in azurerm_subnet.this : k => s.id }
}

output "subnet_names" {
  description = "Map of subnet names."
  value       = { for k, s in azurerm_subnet.this : k => s.name }
}
