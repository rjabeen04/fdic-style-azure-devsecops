###############################################################################
# AKS Cluster (Enterprise / FDIC-style hardened)
###############################################################################

resource "azurerm_kubernetes_cluster" "this" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = var.dns_prefix

  # ✅ Policy + SLA + upgrade channel
  azure_policy_enabled      = true
  sku_tier                  = "Standard"
  disk_encryption_set_id    = var.disk_encryption_set_id
  automatic_channel_upgrade = "stable"

  # ✅ Private cluster + disable local admin
  private_cluster_enabled = true
  private_dns_zone_id     = "System"
  local_account_disabled  = true

  # ✅ Secrets Store CSI Driver rotation
  key_vault_secrets_provider {
    secret_rotation_enabled  = true
    secret_rotation_interval = "30m"
  }

  identity {
    type = "SystemAssigned"
  }

  # ✅ Restrict API server access (required by your Checkov policy)
  api_server_access_profile {
    authorized_ip_ranges = var.api_server_authorized_ip_ranges
  }

  # ✅ Network policy
  network_profile {
    network_plugin = "azure"
    outbound_type  = "loadBalancer"
    network_policy = "calico"
  }

  # ✅ System node pool: only critical addons
  default_node_pool {
    name                         = "system"
    node_count                   = var.node_count
    vm_size                      = var.vm_size
    vnet_subnet_id               = var.subnet_id
    max_pods                     = 50
    only_critical_addons_enabled = true

    # ✅ Encryption + ephemeral OS disks (policy-driven)
    enable_host_encryption = true
    os_disk_type           = "Ephemeral"
  }

  # ✅ Log Analytics
  oms_agent {
    log_analytics_workspace_id = var.log_analytics_workspace_id
  }

  tags = var.tags
}

###############################################################################
# User Node Pool (for application workloads)
###############################################################################

resource "azurerm_kubernetes_cluster_node_pool" "user" {
  name                  = "userpool"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.this.id
  vm_size               = var.user_vm_size
  node_count            = var.user_node_count
  vnet_subnet_id        = var.subnet_id
  max_pods              = 50
  mode                  = "User"

  # ✅ Encryption + ephemeral OS disks (policy-driven)
  enable_host_encryption = true
  os_disk_type           = "Ephemeral"

  tags = var.tags
}

###############################################################################
# Allow AKS to pull images from ACR
###############################################################################

resource "azurerm_role_assignment" "aks_acr_pull" {
  scope                = var.acr_id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.this.kubelet_identity[0].object_id
}
