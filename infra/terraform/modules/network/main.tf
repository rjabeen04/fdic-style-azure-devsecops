locals {
  nsg_prefix = coalesce(var.nsg_name_prefix, var.name)
}

resource "azurerm_virtual_network" "this" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name

  address_space = var.address_space
  tags          = var.tags
}

resource "azurerm_subnet" "this" {
  for_each = var.subnets

  name                 = each.key
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = each.value.address_prefixes

  # Azure requires this Disabled for PE subnets
  private_endpoint_network_policies = each.value.private_endpoint_policies_disabled ? "Disabled" : "Enabled"
}

# ✅ Create one NSG per subnet (enterprise-friendly and passes Checkov)
resource "azurerm_network_security_group" "this" {
  for_each = var.subnets

  name                = "${local.nsg_prefix}-${each.key}-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = var.tags
}

# ✅ Associate each subnet with its NSG (this is what CKV2_AZURE_31 wants)
resource "azurerm_subnet_network_security_group_association" "this" {
  for_each = var.subnets

  subnet_id                 = azurerm_subnet.this[each.key].id
  network_security_group_id = azurerm_network_security_group.this[each.key].id
}
