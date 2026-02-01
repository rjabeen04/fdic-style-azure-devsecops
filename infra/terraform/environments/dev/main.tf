
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
module "rg" {
  source   = "../../modules/rg"
  name     = "${local.prefix}-rg"
  location = var.location
  tags     = local.tags
}

# ============================
# Step 4:: Network (VNet/Subnets)
# ============================
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

module "log_analytics" {
  source              = "../../modules/log_analytics"
  name                = "${local.prefix}-law"
  location            = var.location
  resource_group_name = module.rg.name
  tags                = local.tags
}


############################
# Phase 1 (dev): Foundation
# Start wiring modules here
############################

# 1) Resource Group (module later)
# module "rg" { ... }

# 2) VNet/Subnets (module later)
# module "network" { ... }

# 3) Log Analytics (module later)
# module "log_analytics" { ... }

# 4) ACR (module later)
# module "acr" { ... }

# 5) Disk Encryption Set + Key Vault Key (module later)
# module "des" { ... }

# 6) AKS (you already created the module)
# NOTE: This stays commented until the above outputs exist.
# module "aks" {
#   source = "../../modules/aks"
#
#   name                = "${local.prefix}-aks"
#   location            = var.location
#   resource_group_name = module.rg.name
#   dns_prefix          = "${local.prefix}"
#
#   subnet_id = module.network.aks_subnet_id
#
#   log_analytics_workspace_id = module.log_analytics.workspace_id
#   acr_id                     = module.acr.id
#
#   disk_encryption_set_id          = module.des.id
#   api_server_authorized_ip_ranges = var.api_server_authorized_ip_ranges
#
#   node_count      = 2
#   vm_size         = "Standard_DS2_v2"
#   user_node_count = 2
#   user_vm_size    = "Standard_DS2_v2"
#
#   tags = local.tags
# }

# 7) AppGW + WAF (module later)
# module "appgw_waf" { ... }


