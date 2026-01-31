resource "azurerm_container_registry" "this" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name

  # ✅ Enterprise settings
  sku           = var.sku
  admin_enabled = var.admin_enabled

  # ✅ CKV_AZURE_237 (Premium recommended)
  data_endpoint_enabled = true

  # ✅ CKV_AZURE_165 (geo-replication)
  georeplications = var.georeplications

  tags = var.tags
}
