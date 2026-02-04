data "azurerm_client_config" "current" {}

# 1. Fetch the GitHub Runner's current public IP
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
  public_network_access_enabled = true

  network_acls {
    # 'Deny' with an explicit IP rule is faster and more secure than 'Allow All'
    default_action = "Deny"
    bypass         = "AzureServices"
    
    # trimspace ensures no hidden characters in the IP string
    ip_rules       = [trimspace(data.http.runner_ip.response_body)]
  }

  tags = var.tags
}

# 2. THE WAITER: Forces a 90s pause AFTER the vault is updated
# We rename it to v5 to ensure Terraform sees it as a brand-new mandatory step.
resource "time_sleep" "wait_for_v5_firewall" {
  depends_on = [azurerm_key_vault.this]
  
  triggers = {
    # If the Runner IP changes, the wait must happen again
    runner_ip = data.http.runner_ip.response_body
  }
  
  create_duration = "90s"
}

# 3. THE KEY: Strictly depends on the Waiter
resource "azurerm_key_vault_key" "des" {
  name         = var.key_name
  key_vault_id = azurerm_key_vault.this.id
  key_type     = "RSA"
  key_size     = 2048

  # THIS IS THE CRITICAL LINK
  depends_on = [time_sleep.wait_for_v5_firewall]

  expiration_date = timeadd(timestamp(), "${var.key_expire_days * 24}h")

  key_opts = [
    "decrypt", "encrypt", "sign", "unwrapKey", "verify", "wrapKey",
  ]
}

# 4. PRIVATE ENDPOINT
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
