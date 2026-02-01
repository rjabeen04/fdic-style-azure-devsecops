resource "azurerm_container_registry" "this" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name

  sku           = "Premium"
  admin_enabled = false

  data_endpoint_enabled = true

  georeplications {
    location                = var.replication_location
    zone_redundancy_enabled = true
  }

  # ✅ CKV_AZURE_167 - Cleanup untagged manifests
  retention_policy {
    enabled = true
    days    = var.retention_days # e.g., 7 / 30
  }

  # ✅ CKV_AZURE_164 - Signed/trusted images (content trust)
  trust_policy {
    enabled = true
  }

  tags = var.tags
}
