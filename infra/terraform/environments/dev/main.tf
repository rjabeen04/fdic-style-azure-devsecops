terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.80.0"
    }
  }
}

provider "azurerm" {
  features {}
}

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


