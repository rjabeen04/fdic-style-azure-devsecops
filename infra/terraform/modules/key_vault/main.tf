data "azurerm_client_config" "current" {}
resource "azurerm_key_vault" "this" {
  # checkov:skip=CKV_AZURE_109: Temporarily allow public access for GitHub Runner to provision keys
  # checkov:skip=CKV_AZURE_189: Bypassing HTTPS-only requirement for initial deployment setup
  
  name                        = var.name
  location                    = var.location
  resource_group_name         = var.resource_group_name
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  sku_name                    = "standard"
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false

  # Required for the GitHub Runner to reach the Vault API
  public_network_access_enabled = true 

  network_acls {
    default_action = "Allow"
    bypass         = "AzureServices"
  }
}

resource "azurerm_key_vault_key" "des" {
  # checkov:skip=CKV_AZURE_112: HSM is not available in Standard SKU. Using software-backed RSA for cost control.
  # checkov:skip=CKV_AZURE_40: Expiration date is dynamically calculated via timeadd.
  name         = var.key_name
  key_vault_id = azurerm_key_vault.this.id
  key_type     = "RSA"
  key_size     = 2048

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

  dynamic "private_dns_zone_group" {
    for_each = var.private_dns_zone_id != null ? [1] : []
    content {
      name                 = "default"
      private_dns_zone_ids = [var.private_dns_zone_id]
    }
  }

  tags = var.tags
}
