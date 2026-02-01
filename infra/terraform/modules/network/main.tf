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
