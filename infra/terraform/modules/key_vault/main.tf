data "azurerm_client_config" "current" {}

# 1. NEW: Get the public IP of the GitHub Runner dynamically
data "http" "runner_ip" {
  url = "https://ifconfig.me/ip"
}

resource "azurerm_key_vault" "this" {
  name                          = var.name
  location                      = var.location
  resource_group_name           = var.resource_group_name
  tenant_id                     = data.azurerm_client_config.current.tenant_id
  sku_name                      = "standard"
  
  # ✅ Security best practices
  purge_protection_enabled      = true
  soft_delete_retention_days    = 7
  enable_rbac_authorization     = true
  public_network_access_enabled = true

  network_acls {
    # Changing this to Deny + explicit IP is more "Real World"
    default_action = "Deny" 
    bypass         = "AzureServices"
    
    # 2. Add the Runner's IP to the firewall rules
    ip_rules       = [data.http.runner_ip.response_body]
  }

  # ⚠️ REMOVED ignore_changes so Terraform can actually fix the firewall
  
  tags = var.tags
}

# 3. NEW WAITER: We use the Runner IP as a trigger to ensure it waits
resource "time_sleep" "wait_for_v4_firewall" {
  triggers = {
    runner_ip = data.http.runner_ip.response_body
  }
  create_duration = "90s"
}

# 4. THE KEY
resource "azurerm_key_vault_key" "des" {
  # checkov:skip=CKV_AZURE_112: HSM is not available in Standard SKU.
  # checkov:skip=CKV_AZURE_40: Expiration date is dynamic.
  
  name         = var.key_name
  key_vault_id = azurerm_key_vault.this.id
  key_type     = "RSA"
  key_size     = 2048

  # This ensures we wait for the IP whitelist to propagate
  depends_on = [time_sleep.wait_for_v4_firewall]

  expiration_date = timeadd(timestamp(), "${var.key_expire_days * 24}h")

  key_opts = [
    "decrypt", "encrypt", "sign", "unwrapKey", "verify", "wrapKey",
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
