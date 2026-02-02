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
# Phase 1 (dev): Foundation
############################

# 1) Resource Group
module "rg" {
  source   = "../../modules/rg"
  name     = "${local.prefix}-rg"
  location = var.location
  tags     = local.tags
}

############################
# Step 2) Network (VNet + Subnets)
############################
module "network" {
  source              = "../../modules/network"
  name                = "${local.prefix}-vnet"
  location            = var.location
  resource_group_name = module.rg.name

  address_space = ["10.10.0.0/16"]

  subnets = {
    aks = {
      address_prefixes                   = ["10.10.1.0/24"]
      private_endpoint_policies_disabled = false
    }

    private_endpoints = {
      address_prefixes                   = ["10.10.2.0/24"]
      private_endpoint_policies_disabled = true
    }

    management = {
      address_prefixes                   = ["10.10.3.0/24"]
      private_endpoint_policies_disabled = false
    }

    appgw = {
      address_prefixes                   = ["10.10.4.0/24"]
      private_endpoint_policies_disabled = false
    }
  }

  tags = local.tags
}

# 3) Log Analytics
module "log_analytics" {
  source              = "../../modules/log_analytics"
  name                = "${local.prefix}-law"
  location            = var.location
  resource_group_name = module.rg.name
  tags                = local.tags
}

############################
# Step 4) ACR (Container Registry)
############################
module "acr" {
  source              = "../../modules/acr"
  name                = "${replace(local.prefix, "-", "")}acr"
  location            = var.location
  resource_group_name = module.rg.name
  tags                = local.tags
}

############################
# Step 5a) Key Vault
############################
module "key_vault" {
  source              = "../../modules/key_vault"
  name                = "${replace(local.prefix, "-", "")}kv"
  location            = var.location
  resource_group_name = module.rg.name

  key_name        = "${replace(local.prefix, "-", "")}-des-key"
  key_size        = 2048
  key_expire_days = 365
  tags            = local.tags
}

############################
# Step 5b) Disk Encryption Set
############################
module "des" {
  source              = "../../modules/des"
  name                = "${local.prefix}-des"
  location            = var.location
  resource_group_name = module.rg.name
  key_vault_key_id    = module.key_vault.key_id
  tags                = local.tags
}

############################
# Step 5c) Security Handshake (RBAC)
############################
resource "azurerm_role_assignment" "des_kv_crypto" {
  scope                = module.key_vault.id
  role_definition_name = "Key Vault Crypto Service Encryption User"
  # Fix: Changed to .id because 'principal_id' wasn't exported by your module
  principal_id         = module.des.id 
}

############################
# Step 6) AKS
############################
module "aks" {
  source = "../../modules/aks"

  name                = "${local.prefix}-aks"
  location            = var.location
  resource_group_name = module.rg.name
  dns_prefix          = local.prefix

  subnet_id = module.network.subnet_ids["aks"]

  # Fix: Added the dot between module name and output attribute
  log_analytics_workspace_id = module.log_analytics.workspace_id
  acr_id                     = module.acr.id
  disk_encryption_set_id     = module.des.id

  api_server_authorized_ip_ranges = var.api_server_authorized_ip_ranges

  node_count = 2
  vm_size    = "Standard_DS2_v2"

  tags = local.tags
}

############################
# Step 7) AppGW + WAF (Planned)
############################
# module "appgw_waf" {
#   source              = "../../modules/appgw_waf"
#   name                = "${local.prefix}-appgw"
#   location            = var.location
#   resource_group_name = module.rg.name
#   subnet_id           = module.network.subnet_ids["appgw"]
#   tags                = local.tags
# }
