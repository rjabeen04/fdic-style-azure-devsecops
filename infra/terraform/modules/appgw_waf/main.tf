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

  # ✅ Strong TLS policy (helps with CKV_AZURE_218 expectations)
  ssl_policy {
    policy_type = "Predefined"
    policy_name = "AppGwSslPolicy20170401S"
  }

  frontend_port {
    name = "fe-http"
    port = 80
  }

  frontend_port {
    name = "fe-https"
    port = 443
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

  # ✅ HTTPS cert (for demo); replace with Key Vault in real env
  ssl_certificate {
    name     = "dummy-cert"
    data     = filebase64("${path.module}/dummy.pfx")
    password = var.ssl_cert_password
  }

  # ✅ HTTPS listener (secure)
  http_listener {
    name                           = "https-listener"
    frontend_ip_configuration_name = "frontend-ip"
    frontend_port_name             = "fe-https"
    protocol                       = "Https"
    ssl_certificate_name           = "dummy-cert"
  }

  # ✅ HTTP listener (ONLY for redirect)
  http_listener {
    name                           = "http-listener"
    frontend_ip_configuration_name = "frontend-ip"
    frontend_port_name             = "fe-http"
    protocol                       = "Http"
  }

  # ✅ Redirect HTTP → HTTPS
  redirect_configuration {
    name                 = "http-to-https"
    redirect_type        = "Permanent"
    target_listener_name = "https-listener"
    include_path         = true
    include_query_string = true
  }

  # ✅ Rule: HTTP redirect
  request_routing_rule {
    name                        = "rule-http-redirect"
    priority                    = 1
    rule_type                   = "Basic"
    http_listener_name          = "http-listener"
    redirect_configuration_name = "http-to-https"
  }

  # ✅ Rule: HTTPS to backend
  request_routing_rule {
    name                       = "routing-rule-https"
    priority                   = 10
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
