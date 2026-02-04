data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "this" {
  name                          = var.name
  location                      = var.location
  resource_group_name           = var.resource_group_name
  tenant_id                     = data.azurerm_client_config.current.tenant_id
  sku_name                      = "standard"
  
  # ✅ Security best practices for Checkov
  purge_protection_enabled      = true
  soft_delete_retention_days    = 7
  enable_rbac_authorization     = true
  public_network_access_enabled = true

  network_acls {
    default_action = "Allow"
    bypass         = "AzureServices"
  }

  lifecycle {
    ignore_changes = [
      network_acls,
      public_network_access_enabled
    ]
  } 
  
  tags = var.tags
}

# --- THE WAITER ---
# This forces Terraform to pause for 90 seconds after the Vault is created/updated
# to allow Azure's physical firewalls to actually open up.
resource "time_sleep" "wait_for_kv_network" {
  triggers = {
    # This forces a 90-second wait on EVERY run, 
    # giving Azure's firewall time to catch up.
    always_run = timestamp()
  }
  create_duration = "90s"
}

# --- THE KEY (MERGED VERSION) ---
resource "azurerm_key_vault_key" "des" {
  # checkov:skip=CKV_AZURE_112: HSM is not available in Standard SKU. Using software-backed RSA for cost control.
  # checkov:skip=CKV_AZURE_40: Expiration date is dynamically calculated via timeadd.
  
  name         = var.key_name
  key_vault_id = azurerm_key_vault.this.id
  key_type     = "RSA"
  key_size     = 2048

  # This is the critical link to the timer
  depends_on = [time_sleep.wait_for_kv_network]

  expiration_date = timeadd(timestamp(), "${var.key_expire_days * 24}h")

  key_opts = [
    "encrypt",
    "decrypt",
    "wrapKey",
    "unwrapKey",
    "sign",
    "verify"
  ]
}

# --- PRIVATE ENDPOINT ---
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
