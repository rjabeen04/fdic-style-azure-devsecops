data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "this" {
  # checkov:skip=CKV_AZURE_109: Temporarily allow public access for GitHub Runner to provision keys
  # checkov:skip=CKV_AZURE_189: Public access required for initial bootstrap of keys via GitHub Actions

  
  name                        = var.name
  location                    = var.location
  resource_group_name         = var.resource_group_name
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  sku_name                    = "standard"
  
  purge_protection_enabled    = true
  soft_delete_retention_days  = 7
  enable_rbac_authorization   = true

  public_network_access_enabled = true 

  network_acls {
    default_action = "Allow"
    bypass         = "AzureServices"
  }

  tags = var.tags
}

# In your NSG module or networking main.tf
resource "azurerm_network_security_rule" "appgw_health" {
  name                        = "AllowAppGWHealth"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "65200-65535"
  source_address_prefix       = "GatewayManager" # Critical: This is an Azure Service Tag
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.management.name
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
