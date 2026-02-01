# ============================================
# STAGE ENVIRONMENT - PLACEHOLDER
# This environment exists to demonstrate SDLC structure.
# Stage deployments are gated and not active in this repository.
# ============================================

############################
# Locals / Naming
############################
locals {
  env    = "prod"
  prefix = "fdic-prod"
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

module "log_analytics" {
  source              = "../../modules/log_analytics"
  name                = "${local.prefix}-law"
  location            = var.location
  resource_group_name = module.rg.name
  tags                = local.tags
}

############################
# Phase 1 (prod): Foundation
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
