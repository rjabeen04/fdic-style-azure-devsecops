# checkov:skip=CKV_AZURE_164: Enforced via AKS admission (Gatekeeper/Kyverno) + Azure Policy in Phase 3.
resource "azurerm_container_registry" "this" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name

  # ✅ Make it explicit for Checkov
  sku           = "Premium"
  admin_enabled = false

  # ✅ CKV_AZURE_237
  data_endpoint_enabled = true

  # ✅ CKV_AZURE_165
  georeplications {
    location                = var.replication_location
    zone_redundancy_enabled = true
  }

  tags = var.tags
}
