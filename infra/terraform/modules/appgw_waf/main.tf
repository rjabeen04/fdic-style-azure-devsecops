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

  # ✅ TLS 1.2+ Policy (helps CKV_AZURE_218)
  ssl_policy {
    policy_type = "Predefined"
    policy_name = "AppGwSslPolicy20170401S"
  }

  # ✅ Frontend HTTPS only
  frontend_port {
    name = "fe-https"
    port = 443
  }

  frontend_ip_configuration {
    name                 = "frontend-ip"
    public_ip_address_id = azurerm_public_ip.pip.id
  }

  # ✅ Backend pool (FQDN-based is most common for clean modules)
  backend_address_pool {
    name  = "backend-pool"
    fqdns = [var.backend_fqdn]
  }

  # ✅ Trust backend certificate chain for end-to-end TLS
  # This should be a base64-encoded .cer public cert (root or intermediate used by backend)
  trusted_root_certificate {
    name = "backend-root"
    data = var.backend_root_cert_data
  }

  # ✅ Backend HTTPS settings (end-to-end TLS)
  backend_http_settings {
    name                  = "https-settings"
    cookie_based_affinity = "Disabled"
    port                  = 443
    protocol              = "Https"
    request_timeout       = 60

    trusted_root_certificate_names = ["backend-root"]
  }

  # ✅ Frontend listener certificate (demo/placeholder)
  ssl_certificate {
    name     = "frontend-cert"
    data     = var.frontend_cert_pfx_base64
    password = var.frontend_cert_password
  }

  # ✅ HTTPS listener only (no HTTP listener at all)
  http_listener {
    name                           = "https-listener"
    frontend_ip_configuration_name = "frontend-ip"
    frontend_port_name             = "fe-https"
    protocol                       = "Https"
    ssl_certificate_name           = "frontend-cert"
  }

  # ✅ Rule: HTTPS → backend
  request_routing_rule {
    name                       = "rule-https"
    priority                   = 10
    rule_type                  = "Basic"
    http_listener_name         = "https-listener"
    backend_address_pool_name  = "backend-pool"
    backend_http_settings_name = "https-settings"
  }

  waf_configuration {
    enabled          = true
    firewall_mode    = "Prevention"
    rule_set_type    = "OWASP"
    rule_set_version = "3.2"
  }

  tags = var.tags
}
