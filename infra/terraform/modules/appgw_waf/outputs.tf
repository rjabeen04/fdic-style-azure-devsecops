output "id" {
  value = azurerm_application_gateway.this.id
}

output "public_ip" {
  value = azurerm_public_ip.pip.ip_address
}
