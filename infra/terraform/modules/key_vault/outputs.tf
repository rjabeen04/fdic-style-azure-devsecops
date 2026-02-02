output "key_id" {
  description = "Key Vault key ID for DES"
  value       = azurerm_key_vault_key.des.id
}

output "id" {
  description = "Key Vault ID"
  value       = azurerm_key_vault.this.id
}
