resource "azurerm_container_registry" "this" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name

  sku           = "Premium"
  admin_enabled = false

  # ✅ CKV_AZURE_139
  public_network_access_enabled = false

  # ✅ CKV_AZURE_233
  zone_redundancy_enabled = true

  data_endpoint_enabled = true

  georeplications {
    location                = var.replication_location
    zone_redundancy_enabled = true
  }

  # ✅ CKV_AZURE_166 - Image quarantine
  quarantine_policy {
  enabled = true
 }


  # ✅ CKV_AZURE_167 - Cleanup untagged manifests
  retention_policy {
    enabled = true
    days    = var.retention_days
  }

  # ✅ CKV_AZURE_164 - Signed/trusted images (content trust)
  trust_policy {
    enabled = true
  }

  # (Optional hardening)
  # network_rule_set {
  #   default_action = "Deny"
  # }

  tags = var.tags
}
