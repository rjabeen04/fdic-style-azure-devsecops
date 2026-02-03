############################
# Locals / Naming
############################
locals {
  env    = "dev"
  prefix = "fdic-dev"

  tags = {
    environment = local.env
    project     = "fdic-style-azure-devsecops"
    managed_by  = "terraform"
  }
}

############################
# Phase 1: Foundation
############################

module "rg" {
  source   = "../../modules/rg"
  name     = "${local.prefix}-rg"
  location = var.location
  tags     = local.tags
}

module "network" {
  source              = "../../modules/network"
  name                = "${local.prefix}-vnet"
  location            = var.location
  resource_group_name = module.rg.name
  address_space       = ["10.10.0.0/16"]

  subnets = {
    aks               = { address_prefixes = ["10.10.1.0/24"] }
    private_endpoints = { address_prefixes = ["10.10.2.0/24"] }
    management        = { address_prefixes = ["10.10.3.0/24"] }
    appgw             = { address_prefixes = ["10.10.4.0/24"] }
  }
  tags = local.tags
}

module "log_analytics" {
  source              = "../../modules/log_analytics"
  name                = "${local.prefix}-law"
  location            = var.location
  resource_group_name = module.rg.name
  tags                = local.tags
}

############################
# Phase 2: Security & Storage
############################

# 4) Azure Container Registry (For your musical-volunteer images)
module "acr" {
  source              = "../../modules/acr"
  name                = "acr${replace(local.prefix, "-", "")}" # ACR names must be alphanumeric
  location            = var.location
  resource_group_name = module.rg.name
  tags                = local.tags
}

# 5) Key Vault (The Secret Store)
module "key_vault" {
  source              = "../../modules/key_vault"
  name                = "${local.prefix}-kv"
  location            = var.location
  resource_group_name = module.rg.name
  tags                = local.tags
}

# 6) Disk Encryption Set - Fixed arguments
module "des" {
  source              = "../../modules/des"
  name                = "${local.prefix}-des"
  location            = var.location
  resource_group_name = module.rg.name
  
  # Changed from key_vault_id to the specific key ID the module expects
  key_vault_key_id    = module.key_vault.key_id 
  
  tags                = local.tags
}

############################
# Phase 3: Traffic (The App Gateway)
############################

# 7) AppGW + WAF - Fixed with SSL argument
module "appgw_waf" {
  source              = "../../modules/appgw_waf"
  name                = "${local.prefix}-appgw"
  resource_group_name = module.rg.name
  location            = var.location
  subnet_id           = module.network.subnet_ids["appgw"]
  
  # Added to satisfy the module requirement
  # In a real production scenario, we would pull this from Key Vault
  ssl_cert_password   = "DummyPassword123!" 
  
  tags                = local.tags
}
