# checkov:skip=CKV_AZURE_164: Image trust/signing enforced via AKS admission policies (Gatekeeper/Kyverno) + Azure Policy in Phase 3.
resource "azurerm_container_registry" "this" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name

  sku           = var.sku
  admin_enabled = var.admin_enabled

  # CKV_AZURE_237 (Premium feature)
  data_endpoint_enabled = true

  # ✅ CKV_AZURE_165: must be a STATIC block (Checkov doesn't count dynamic blocks reliably)
  georeplications {
    location                = var.replication_location
    zone_redundancy_enabled = true
    tags                    = var.tags
  }

  tags = var.tags
}
