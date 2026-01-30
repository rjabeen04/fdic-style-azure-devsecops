resource "azurerm_kubernetes_cluster" "this" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = var.dns_prefix

  azure_policy_enabled = true
  sku_tier = "Standard"
  disk_encryption_set_id = var.disk_encryption_set_id
  automatic_channel_upgrade = "stable"

 key_vault_secrets_provider {
  secret_rotation_enabled  = true
  secret_rotation_interval = "30m"
}

resource "azurerm_kubernetes_cluster_node_pool" "user" {
  name                  = "userpool"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.this.id
  vm_size               = var.user_vm_size
  node_count            = var.user_node_count
  vnet_subnet_id        = var.subnet_id
  max_pods              = 50
  mode                  = "User"

  tags = var.tags
}



  identity {
    type = "SystemAssigned"
  }

  api_server_access_profile {
  authorized_ip_ranges = var.api_server_authorized_ip_ranges
 }

  network_profile {
    network_plugin = "azure"
    outbound_type  = "loadBalancer"
  }

default_node_pool {
  name                 = "system"
  node_count           = var.node_count
  vm_size              = var.vm_size
  vnet_subnet_id       = var.subnet_id
  max_pods             = 50

  # ✅ Helps satisfy CKV_AZURE_232 expectations
  only_critical_addons_enabled = true
}


  oms_agent {
    log_analytics_workspace_id = var.log_analytics_workspace_id
  }

  tags = var.tags
}

# Allow AKS to pull images from ACR
resource "azurerm_role_assignment" "aks_acr_pull" {
  scope                = var.acr_id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.this.kubelet_identity[0].object_id
}
