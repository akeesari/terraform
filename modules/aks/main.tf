# User-assigned identity for AKS cluster
resource "azurerm_user_assigned_identity" "aks" {
  count               = var.enable_cluster && var.identity_type == "UserAssigned" ? 1 : 0
  name                = "id-${coalesce(var.name, var.cluster_name)}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  lifecycle {
    ignore_changes = [tags["CreatedDate"], tags["LastModified"]]
  }
}

locals {
  aks_identity_principal_id = var.identity_type == "UserAssigned" ? (
    try(azurerm_user_assigned_identity.aks[0].principal_id, null)
    ) : (
    try(azurerm_kubernetes_cluster.this[0].identity[0].principal_id, null)
  )
}

resource "azurerm_kubernetes_cluster" "this" {
  count               = var.enable_cluster ? 1 : 0
  name                = coalesce(var.name, var.cluster_name)
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = var.dns_prefix
  kubernetes_version  = var.kubernetes_version
  sku_tier            = var.sku_tier
  tags                = var.tags

  # Private cluster configuration
  private_cluster_enabled = var.enable_private_cluster
  private_dns_zone_id     = var.enable_private_cluster ? var.private_dns_zone_id : null

  # Workload identity and OIDC issuer
  workload_identity_enabled = var.enable_workload_identity
  oidc_issuer_enabled       = var.oidc_issuer_enabled

  # Security settings
  local_account_disabled = var.local_account_disabled

  # Automatic upgrades
  automatic_upgrade_channel = var.automatic_upgrade_channel

  # API server access profile (provider v4.x+ structure)
  dynamic "api_server_access_profile" {
    for_each = var.api_server_authorized_ip_ranges != null || !var.enable_private_cluster ? [1] : []
    content {
      authorized_ip_ranges = var.api_server_authorized_ip_ranges
    }
  }

  default_node_pool {
    name                         = "system"
    node_count                   = var.node_count
    vm_size                      = var.node_vm_size
    temporary_name_for_rotation  = var.temporary_name_for_rotation
    auto_scaling_enabled         = var.enable_auto_scaling
    min_count                    = var.enable_auto_scaling ? var.min_node_count : null
    max_count                    = var.enable_auto_scaling ? var.max_node_count : null
    only_critical_addons_enabled = var.only_critical_addons_enabled

    # Network configuration
    vnet_subnet_id = var.vnet_subnet_id

    # Node pool settings
    zones                   = var.node_pool_availability_zones
    max_pods                = var.node_pool_max_pods
    os_disk_size_gb         = var.node_pool_os_disk_size_gb
    os_disk_type            = var.node_pool_os_disk_type
    node_labels             = var.node_labels
    host_encryption_enabled = var.host_encryption_enabled

    # Always render upgrade_settings with coalesced defaults to prevent plan drift removal.
    upgrade_settings {
      max_surge                     = coalesce(var.node_upgrade_max_surge, "10%")
      drain_timeout_in_minutes      = coalesce(var.node_upgrade_drain_timeout_minutes, 0)
      node_soak_duration_in_minutes = coalesce(var.node_upgrade_soak_duration_minutes, 0)
    }
  }

  # Network profile
  network_profile {
    network_plugin      = var.network_plugin
    network_plugin_mode = var.network_plugin_mode
    network_policy      = var.network_policy
    service_cidr        = var.service_cidr
    dns_service_ip      = var.dns_service_ip
    outbound_type       = var.outbound_type
  }

  # Azure AD / Entra ID integration
  dynamic "azure_active_directory_role_based_access_control" {
    for_each = var.enable_azure_ad ? [1] : []
    content {
      azure_rbac_enabled     = var.enable_azure_rbac
      admin_group_object_ids = var.azure_ad_admin_group_ids
    }
  }

  # Azure Monitor Container Insights
  dynamic "oms_agent" {
    for_each = var.enable_azure_monitor && var.log_analytics_workspace_id != null ? [1] : []
    content {
      log_analytics_workspace_id = var.log_analytics_workspace_id
    }
  }

  # Azure Key Vault Secrets Provider CSI driver
  dynamic "key_vault_secrets_provider" {
    for_each = var.enable_key_vault_secrets_provider ? [1] : []
    content {
      secret_rotation_enabled = var.secret_rotation_enabled
    }
  }

  # Azure Policy add-on
  azure_policy_enabled = var.enable_azure_policy

  # Image Cleaner — auto-remove unused container images
  image_cleaner_enabled        = var.image_cleaner_enabled
  image_cleaner_interval_hours = var.image_cleaner_interval_hours

  # Workload Autoscaler Profile (KEDA + VPA)
  dynamic "workload_autoscaler_profile" {
    for_each = var.keda_enabled || var.vertical_pod_autoscaler_enabled ? [1] : []
    content {
      keda_enabled                    = var.keda_enabled
      vertical_pod_autoscaler_enabled = var.vertical_pod_autoscaler_enabled
    }
  }

  # Microsoft Defender for Containers
  dynamic "microsoft_defender" {
    for_each = var.microsoft_defender_enabled && var.log_analytics_workspace_id != null ? [1] : []
    content {
      log_analytics_workspace_id = var.log_analytics_workspace_id
    }
  }

  # Web App Routing (Application Routing add-on) — managed nginx ingress
  dynamic "web_app_routing" {
    for_each = var.enable_web_app_routing ? [1] : []
    content {
      dns_zone_ids = var.web_app_routing_dns_zone_ids
    }
  }

  # HTTP application routing (deprecated)
  http_application_routing_enabled = var.enable_http_application_routing

  # Cluster autoscaler profile
  dynamic "auto_scaler_profile" {
    for_each = var.auto_scaler_profile != null ? [var.auto_scaler_profile] : []
    content {
      expander                     = auto_scaler_profile.value.expander
      balance_similar_node_groups  = auto_scaler_profile.value.balance_similar_node_groups
      max_graceful_termination_sec = auto_scaler_profile.value.max_graceful_termination_sec
      scale_down_delay_after_add   = auto_scaler_profile.value.scale_down_delay_after_add
      scale_down_unneeded          = auto_scaler_profile.value.scale_down_unneeded
      scan_interval                = auto_scaler_profile.value.scan_interval
    }
  }

  # Maintenance window (basic allowed/denied windows)
  dynamic "maintenance_window" {
    for_each = var.maintenance_window != null ? [var.maintenance_window] : []
    content {
      allowed {
        day   = maintenance_window.value.day_of_week
        hours = [maintenance_window.value.start_hour]
      }
    }
  }

  # Maintenance window for automatic Kubernetes upgrades
  dynamic "maintenance_window_auto_upgrade" {
    for_each = var.maintenance_window_auto_upgrade != null ? [var.maintenance_window_auto_upgrade] : []
    content {
      frequency    = maintenance_window_auto_upgrade.value.frequency
      interval     = maintenance_window_auto_upgrade.value.interval
      duration     = maintenance_window_auto_upgrade.value.duration
      day_of_week  = maintenance_window_auto_upgrade.value.day_of_week
      day_of_month = maintenance_window_auto_upgrade.value.day_of_month
      week_index   = maintenance_window_auto_upgrade.value.week_index
      start_time   = maintenance_window_auto_upgrade.value.start_time
      utc_offset   = maintenance_window_auto_upgrade.value.utc_offset
      start_date   = maintenance_window_auto_upgrade.value.start_date

      dynamic "not_allowed" {
        for_each = maintenance_window_auto_upgrade.value.not_allowed != null ? maintenance_window_auto_upgrade.value.not_allowed : []
        content {
          start = not_allowed.value.start
          end   = not_allowed.value.end
        }
      }
    }
  }

  # Maintenance window for node OS patching
  dynamic "maintenance_window_node_os" {
    for_each = var.maintenance_window_node_os != null ? [var.maintenance_window_node_os] : []
    content {
      frequency    = maintenance_window_node_os.value.frequency
      interval     = maintenance_window_node_os.value.interval
      duration     = maintenance_window_node_os.value.duration
      day_of_week  = maintenance_window_node_os.value.day_of_week
      day_of_month = maintenance_window_node_os.value.day_of_month
      week_index   = maintenance_window_node_os.value.week_index
      start_time   = maintenance_window_node_os.value.start_time
      utc_offset   = maintenance_window_node_os.value.utc_offset
      start_date   = maintenance_window_node_os.value.start_date

      dynamic "not_allowed" {
        for_each = maintenance_window_node_os.value.not_allowed != null ? maintenance_window_node_os.value.not_allowed : []
        content {
          start = not_allowed.value.start
          end   = not_allowed.value.end
        }
      }
    }
  }

  identity {
    type         = var.identity_type
    identity_ids = var.identity_type == "UserAssigned" ? [azurerm_user_assigned_identity.aks[0].id] : null
  }

  lifecycle {
    ignore_changes = [
      tags["CreatedDate"],
      tags["LastModified"],
      default_node_pool[0].node_count # Ignored when autoscaling is enabled
    ]
  }
}

# =============================================================================
# Role Assignments
# =============================================================================

# AcrPull — allows the kubelet identity to pull images from ACR
resource "azurerm_role_assignment" "acr_pull" {
  count                = var.enable_acr_pull_role && var.enable_cluster && var.enable_acr ? 1 : 0
  scope                = var.acr_id
  role_definition_name = "AcrPull"
  principal_id         = try(azurerm_kubernetes_cluster.this[0].kubelet_identity[0].object_id, null)
  depends_on           = [azurerm_kubernetes_cluster.this]
}

# Network Contributor — required when AKS uses userDefinedRouting (UDR) to manage subnet routes.
# Not needed for loadBalancer outbound type.
resource "azurerm_role_assignment" "network_contributor" {
  count                = var.enable_cluster && var.outbound_type == "userDefinedRouting" ? 1 : 0
  scope                = var.vnet_subnet_id
  role_definition_name = "Network Contributor"
  principal_id         = local.aks_identity_principal_id
  depends_on           = [azurerm_kubernetes_cluster.this, azurerm_user_assigned_identity.aks]
}

# AKS RBAC Cluster Admin per-user/group
resource "azurerm_role_assignment" "cluster_admin" {
  for_each             = var.enable_cluster ? toset(var.cluster_admin_ids) : toset([])
  scope                = azurerm_kubernetes_cluster.this[0].id
  role_definition_name = "Azure Kubernetes Service RBAC Cluster Admin"
  principal_id         = each.value
  depends_on           = [azurerm_kubernetes_cluster.this]
}

# =============================================================================
# Diagnostic Settings
# =============================================================================

resource "azurerm_monitor_diagnostic_setting" "aks" {
  count                      = var.enable_cluster && var.enable_diagnostic_settings && var.enable_azure_monitor ? 1 : 0
  name                       = "diag-${coalesce(var.name, var.cluster_name)}"
  target_resource_id         = azurerm_kubernetes_cluster.this[0].id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log { category = "kube-apiserver" }
  enabled_log { category = "kube-audit" }
  enabled_log { category = "kube-audit-admin" }
  enabled_log { category = "kube-controller-manager" }
  enabled_log { category = "kube-scheduler" }
  enabled_log { category = "cluster-autoscaler" }
  enabled_log { category = "guard" }
  enabled_log { category = "cloud-controller-manager" }
  enabled_log { category = "csi-azuredisk-controller" }
  enabled_log { category = "csi-azurefile-controller" }
  enabled_log { category = "csi-snapshot-controller" }
  enabled_metric { category = "AllMetrics" }

  depends_on = [azurerm_kubernetes_cluster.this]
}

# =============================================================================
# Monitoring Alerts
# =============================================================================

resource "azurerm_monitor_metric_alert" "cpu_usage" {
  count               = var.enable_cluster && var.enable_metric_alerts && var.action_group_id != null ? 1 : 0
  name                = "CPU Usage Percentage ${var.alert_cpu_threshold} percent - ${coalesce(var.name, var.cluster_name)}"
  resource_group_name = var.resource_group_name
  scopes              = [azurerm_kubernetes_cluster.this[0].id]
  description         = "Action will be triggered when average node CPU usage percentage is greater than ${var.alert_cpu_threshold}%."
  frequency           = "PT30M"
  window_size         = "PT30M"
  severity            = 3
  auto_mitigate       = true
  tags                = var.tags

  criteria {
    metric_namespace = "Microsoft.ContainerService/managedClusters"
    metric_name      = "node_cpu_usage_percentage"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = var.alert_cpu_threshold
  }

  action { action_group_id = var.action_group_id }

  depends_on = [azurerm_kubernetes_cluster.this]

  lifecycle { ignore_changes = [tags["CreatedDate"], tags["LastModified"]] }
}

resource "azurerm_monitor_metric_alert" "memory_usage" {
  count               = var.enable_cluster && var.enable_metric_alerts && var.action_group_id != null ? 1 : 0
  name                = "Memory Working Set Percentage ${var.alert_memory_threshold} percent - ${coalesce(var.name, var.cluster_name)}"
  resource_group_name = var.resource_group_name
  scopes              = [azurerm_kubernetes_cluster.this[0].id]
  description         = "Action will be triggered when average node memory working set percentage is greater than ${var.alert_memory_threshold}%."
  frequency           = "PT30M"
  window_size         = "PT30M"
  severity            = 3
  auto_mitigate       = true
  tags                = var.tags

  criteria {
    metric_namespace = "Microsoft.ContainerService/managedClusters"
    metric_name      = "node_memory_working_set_percentage"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = var.alert_memory_threshold
  }

  action { action_group_id = var.action_group_id }

  depends_on = [azurerm_kubernetes_cluster.this]

  lifecycle { ignore_changes = [tags["CreatedDate"], tags["LastModified"]] }
}

# =============================================================================
# Worker Node Pools (system pool + GPU Spot + CPU Spot burst)
# =============================================================================

resource "azurerm_kubernetes_cluster_node_pool" "worker" {
  for_each = var.enable_cluster ? { for np in var.worker_node_pools : np.name => np } : {}

  kubernetes_cluster_id       = azurerm_kubernetes_cluster.this[0].id
  name                        = each.value.name
  vm_size                     = each.value.vm_size
  mode                        = each.value.mode
  os_type                     = each.value.os_type
  temporary_name_for_rotation = each.value.temporary_name_for_rotation

  # Spot vs Regular priority
  priority        = each.value.priority
  eviction_policy = each.value.priority == "Spot" ? each.value.eviction_policy : null
  spot_max_price  = each.value.priority == "Spot" ? each.value.spot_max_price : null

  # Autoscaling — Spot pools must always use autoscaling (min_count can be 0)
  auto_scaling_enabled = each.value.auto_scaling_enabled
  node_count           = each.value.auto_scaling_enabled ? null : each.value.node_count
  min_count            = each.value.auto_scaling_enabled ? each.value.min_count : null
  max_count            = each.value.auto_scaling_enabled ? each.value.max_count : null

  # Node configuration
  max_pods                = each.value.max_pods
  os_disk_size_gb         = each.value.os_disk_size_gb
  host_encryption_enabled = each.value.host_encryption_enabled
  workload_runtime        = each.value.workload_runtime

  # Network
  vnet_subnet_id = var.vnet_subnet_id

  # Availability zones (inherit cluster setting)
  zones = var.node_pool_availability_zones

  # Labels and taints for workload isolation
  node_labels = merge(
    try(each.value.node_labels, {}),
    { "nodepool" = each.value.name }
  )
  node_taints = try(each.value.node_taints, [])

  # upgrade_settings is not supported on Spot node pools
  dynamic "upgrade_settings" {
    for_each = each.value.priority == "Spot" ? [] : [1]
    content {
      max_surge                     = coalesce(try(each.value.max_surge, null), "10%")
      drain_timeout_in_minutes      = coalesce(try(each.value.drain_timeout_minutes, null), 0)
      node_soak_duration_in_minutes = coalesce(try(each.value.soak_duration_minutes, null), 0)
    }
  }

  tags = var.tags

  lifecycle {
    ignore_changes = [
      tags["CreatedDate"],
      tags["LastModified"],
      node_count, # Ignored when autoscaling is enabled
      gpu_driver  # Azure auto-sets to "Install" on GPU-capable SKUs (NC-series)
    ]
  }
}
