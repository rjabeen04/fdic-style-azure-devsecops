resource "azurerm_user_assigned_identity" "des" {
  name                = "${var.name}-uai"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_disk_encryption_set" "this" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name

  key_vault_key_id = var.key_vault_key_id

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.des.id]
  }

  tags = var.tags
}
