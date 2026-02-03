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
# Phase 2: Security & Storage 
############################

# 4) ACR (For your musical-volunteer images)
module "acr" {
  source              = "../../modules/acr"
  # Using a unique name to avoid "Already Exists" errors
  name                = "acrfdicdev0202" 
  location            = var.location
  resource_group_name = module.rg.name
  tags                = local.tags
}

# 5) Key Vault (Required for Encryption)
module "key_vault" {
  source              = "../../modules/key_vault"
  name                = "${local.prefix}-kv"
  location            = var.location
  resource_group_name = module.rg.name
  tags                = local.tags
}

# 6) Disk Encryption Set
module "des" {
  source              = "../../modules/des"
  name                = "${local.prefix}-des"
  location            = var.location
  resource_group_name = module.rg.name
  key_vault_key_id    = module.key_vault.key_id 
  tags                = local.tags
}

############################
# Phase 3: Traffic & Compute
############################

# 7) AppGW + WAF (Using the variables we just fixed!)
module "appgw_waf" {
  source                    = "../../modules/appgw_waf"
  name                      = "${local.prefix}-appgw"
  resource_group_name       = module.rg.name
  location                  = var.location
  subnet_id                 = module.network.subnet_ids["appgw"] # Make sure "appgw" is in your subnets list!
  
  backend_fqdn              = "musical-volunteer.local"
  backend_root_cert_data    = "" 
  frontend_cert_pfx_base64  = ""
  frontend_cert_password    = "DummyPassword123!"
  ssl_cert_password         = "DummyPassword123!"

  tags                      = local.tags
}

# 8) AKS (The Cluster)
# Note: This will take ~10-15 minutes to deploy
module "aks" {
  source = "../../modules/aks"

  name                = "${local.prefix}-aks"
  location            = var.location
  resource_group_name = module.rg.name
  dns_prefix          = local.prefix

  subnet_id = module.network.subnet_ids["aks"]

  log_analytics_workspace_id = module.log_analytics.workspace_id
  acr_id                     = module.acr.id
  disk_encryption_set_id      = module.des.id

  node_count      = 2
  vm_size         = "Standard_DS2_v2"
  user_node_count = 2
  user_vm_size    = "Standard_DS2_v2"

  tags = local.tags
}




