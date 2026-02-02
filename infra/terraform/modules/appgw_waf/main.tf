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

  # ✅ TLS policy (scanner-friendly)
  ssl_policy {
    policy_type = "Predefined"
    policy_name = "AppGwSslPolicy20170401S"
  }

  # ✅ HTTPS only
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

  fqdns = [
    var.backend_fqdn
  ]
} 
  
  # ✅ Trust backend cert chain (end-to-end TLS)
  trusted_root_certificate {
    name = "backend-root"
    data = filebase64("${path.module}/backend-root.cer")
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


  # Demo cert (replace with Key Vault later)
  ssl_certificate {
    name     = "dummy-cert"
    data     = filebase64("${path.module}/dummy.pfx")
    password = var.ssl_cert_password
  }

  # ✅ HTTPS listener only
  http_listener {
    name                           = "https-listener"
    frontend_ip_configuration_name = "frontend-ip"
    frontend_port_name             = "fe-https"
    protocol                       = "Https"
    ssl_certificate_name           = "dummy-cert"
  }

  # ✅ HTTPS routing rule
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
