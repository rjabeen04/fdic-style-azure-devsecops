data "azurerm_client_config" "current" {}

# Get the runner's IP
data "http" "runner_ip" {
  url = "https://ifconfig.me/ip"
}

resource "azurerm_key_vault" "this" {
  name                          = var.name
  location                      = var.location
  resource_group_name           = var.resource_group_name
  tenant_id                     = data.azurerm_client_config.current.tenant_id
  sku_name                      = "standard"
  
  purge_protection_enabled      = true
  soft_delete_retention_days    = 7
  enable_rbac_authorization     = true
  
  # Force this to true to ensure the firewall actually looks at our IP rules
  public_network_access_enabled = true

  network_acls {
    default_action = "Deny"
    bypass         = "AzureServices"
    # trimspace is mandatory to avoid "Forbidden" errors due to hidden characters
    ip_rules       = [trimspace(data.http.runner_ip.response_body)]
  }

  tags = var.tags
}

# --- THE FORCED WAITER (v9) ---
resource "time_sleep" "wait_for_v9_firewall" {
  # This makes the sleep wait until the Vault firewall change is fully CONFIRMED
  depends_on = [azurerm_key_vault.this]
  
  triggers = {
    runner_ip = data.http.runner_ip.response_body
  }
  
  # Bumping to 150s because your environment is experiencing high latency
  create_duration = "150s" 
}

resource "azurerm_key_vault_key" "des" {
  name         = var.key_name
  key_vault_id = azurerm_key_vault.this.id
  key_type     = "RSA"
  key_size     = 2048

  # This is the strictly enforced order: Vault -> Wait -> Key
  depends_on = [time_sleep.wait_for_v9_firewall]

  expiration_date = timeadd(timestamp(), "${var.key_expire_days * 24}h")

  key_opts = ["decrypt", "encrypt", "sign", "unwrapKey", "verify", "wrapKey"]

  lifecycle {
    ignore_changes = [expiration_date]
  }
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
