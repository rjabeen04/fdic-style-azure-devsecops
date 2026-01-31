resource "azurerm_container_registry" "this" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name

  sku           = var.sku
  admin_enabled = var.admin_enabled

  # Dedicated data endpoint (Premium feature)
  data_endpoint_enabled = true

  # ✅ Geo-replication (Premium feature)
  dynamic "georeplications" {
    for_each = toset(var.replication_locations)
    content {
      location                = georeplications.value
      zone_redundancy_enabled = true
      tags                    = var.tags
    }
  }

  tags = var.tags
}

