data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "this" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  tenant_id           = data.azurerm_client_config.current.tenant_id

  sku_name = var.sku_name

  purge_protection_enabled      = var.purge_protection_enabled
  soft_delete_retention_days    = var.soft_delete_retention_days
  enable_rbac_authorization     = true
  public_network_access_enabled = false

  network_acls {
    default_action = "Deny"
    bypass         = "AzureServices"
  }

  tags = var.tags
}
resource "azurerm_key_vault_key" "des" {
  name         = var.key_name
  key_vault_id = azurerm_key_vault.this.id
  key_type     = "RSA-HSM"
  key_size     = var.key_size

  # ✅ Fixes CKV_AZURE_40
  expiration_date = timeadd(timestamp(), "${var.key_expire_days * 24}h")

  key_opts = [
    "encrypt",
    "decrypt",
    "wrapKey",
    "unwrapKey",
  ]
}
resource "azurerm_private_endpoint" "kv" {
  count               = var.private_endpoint_enabled ? 1 : 0
  name                = "${var.name}-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "${var.name}-pe-conn"
    private_connection_resource_id = azurerm_key_vault.this.id
    subresource_names              = ["vault"]
    is_manual_connection           = false
  }

  tags = var.tags
}

resource "azurerm_private_endpoint_private_dns_zone_group" "kv" {
  count               = var.private_dns_zone_id != null ? 1 : 0
  name                = "default"
  private_endpoint_id = azurerm_private_endpoint.kv[0].id

  private_dns_zone_ids = [var.private_dns_zone_id]
}


resource "azurerm_private_dns_zone_group" "kv" {
  count               = var.private_endpoint_enabled && var.private_dns_zone_id != null ? 1 : 0
  name                = "default"
  private_endpoint_id = azurerm_private_endpoint.kv[0].id

  private_dns_zone_ids = [var.private_dns_zone_id]
}
