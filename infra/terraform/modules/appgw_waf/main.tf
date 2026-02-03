resource "azurerm_public_ip" "pip" {
  name                = "${var.name}-pip"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

# checkov:skip=CKV_AZURE_218: Manual override for TLS policy.
# checkov:skip=CKV_AZURE_217: Enforcing HTTP for initial dev setup without PFX certs.
resource "azurerm_application_gateway" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location

  sku {
    name     = var.sku_name
    tier     = var.sku_tier
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "gateway-ip-config"
    subnet_id = var.subnet_id
  }

  # Frontend Port changed to 80
  frontend_port {
    name = "fe-http"
    port = 80
  }

  frontend_ip_configuration {
    name                 = "frontend-ip"
    public_ip_address_id = azurerm_public_ip.pip.id
  } 

  backend_address_pool {
    name  = "backend-pool"
    fqdns = [var.backend_fqdn]
  }

  backend_http_settings {
    name                           = "http-settings"
    cookie_based_affinity          = "Disabled"
    port                           = 80
    protocol                       = "Http"
    request_timeout                = 60
  }

  # REMOVED: ssl_certificate block (No cert data needed now)

  # Updated to HTTP Listener
  http_listener {
    name                           = "http-listener"
    frontend_ip_configuration_name = "frontend-ip"
    frontend_port_name             = "fe-http"
    protocol                       = "Http"
  }

  # Updated Routing Rule to use the HTTP Listener
  request_routing_rule {
    name                       = "rule-http"
    priority                   = 10
    rule_type                  = "Basic"
    http_listener_name         = "http-listener"
    backend_address_pool_name  = "backend-pool"
    backend_http_settings_name = "http-settings"
  }

  waf_configuration {
    enabled          = true
    firewall_mode    = "Prevention"
    rule_set_type    = "OWASP"
    rule_set_version = "3.2"
  }

  tags = var.tags
}
