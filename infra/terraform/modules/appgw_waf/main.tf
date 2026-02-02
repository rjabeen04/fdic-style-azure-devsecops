resource "azurerm_public_ip" "pip" {
  name                = "${var.name}-pip"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

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

  # ✅ ADD THIS BLOCK - This satisfies CKV_AZURE_218
  ssl_policy {
    policy_type = "Predefined"
    policy_name = "AppGwSslPolicy20170401S" 
  }

  frontend_port {
    name = "https-port"
    port = 443
  }

  frontend_port {
    name = "https-port"
    port = 443 # ✅ Fixes CKV_AZURE_217 (Moving away from Port 80)
  }

  frontend_ip_configuration {
    name                 = "frontend-ip"
    public_ip_address_id = azurerm_public_ip.pip.id
  }

  backend_address_pool {
    name = "backend-pool"
  }

  backend_http_settings {
    name                  = "http-settings"
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 60
  }

  # ✅ Added TLS Policy to fix CKV_AZURE_218
  ssl_policy {
    policy_type = "Predefined"
    policy_name = "AppGwSslPolicy20170401S" 
  }

  http_listener {
    name                           = "https-listener"
    frontend_ip_configuration_name = "frontend-ip"
    frontend_port_name             = "https-port"
    protocol                       = "Https" # ✅ Changed to HTTPS
    ssl_certificate_name           = "dummy-cert"
  }

  # Note: In a real environment, you'd fetch this from Key Vault
  ssl_certificate {
    name     = "dummy-cert"
    data     = filebase64("${path.module}/dummy.pfx") # You'll need a placeholder pfx file in the module folder
    password = "password"
  }

  request_routing_rule {
    name                       = "routing-rule"
    priority                   = 1
    rule_type                  = "Basic"
    http_listener_name         = "https-listener"
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
