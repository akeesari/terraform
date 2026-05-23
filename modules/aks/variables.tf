variable "resource_group_name" {
  type        = string
  description = "Target Azure resource group for the AKS cluster."
}

variable "location" {
  type        = string
  description = "Azure region for the AKS cluster."
}

variable "name" {
  type        = string
  description = "AKS cluster name. Prefer this over cluster_name."
  default     = null
}

variable "cluster_name" {
  type        = string
  description = "DEPRECATED: use var.name instead. Kept for backward compatibility — value is used when var.name is null."
  default     = null
}

variable "dns_prefix" {
  type        = string
  description = "DNS prefix used for the AKS API server FQDN."
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to all AKS resources."
  default     = {}
}

# =============================================================================
# Cluster Toggle
# =============================================================================

variable "enable_cluster" {
  type        = bool
  description = "Toggle creation of the AKS cluster and all child resources."
  default     = true
}

# =============================================================================
# AKS SKU and Tier
# =============================================================================

variable "sku_tier" {
  type        = string
  description = "AKS SKU tier: Free or Standard. Standard includes a 99.95% SLA and is recommended for production. Use Free only for dev/test."
  default     = "Standard"

  validation {
    condition     = contains(["Free", "Standard"], var.sku_tier)
    error_message = "sku_tier must be 'Free' or 'Standard'."
  }
}

variable "kubernetes_version" {
  type        = string
  description = "Kubernetes version (e.g. '1.31')."
}

variable "automatic_upgrade_channel" {
  type        = string
  description = "Automatic upgrade channel: none, patch, rapid, stable, or node-image. Null disables auto-upgrade."
  default     = null

  validation {
    condition     = var.automatic_upgrade_channel == null ? true : contains(["none", "patch", "rapid", "stable", "node-image"], var.automatic_upgrade_channel)
    error_message = "automatic_upgrade_channel must be one of: none, patch, rapid, stable, node-image."
  }
}

variable "local_account_disabled" {
  type        = bool
  description = "Disable the local kubeadmin account. Must be true when using Azure AD/Entra ID RBAC — keeping local accounts active is a security risk."
  default     = true
}

# =============================================================================
# Identity
# =============================================================================

variable "identity_type" {
  type        = string
  description = "Managed identity type for the AKS cluster: SystemAssigned or UserAssigned."
  default     = "SystemAssigned"

  validation {
    condition     = contains(["SystemAssigned", "UserAssigned"], var.identity_type)
    error_message = "identity_type must be 'SystemAssigned' or 'UserAssigned'."
  }
}

variable "cluster_admin_ids" {
  type        = list(string)
  description = "Azure AD/Entra ID object IDs (users or groups) to grant AKS RBAC Cluster Admin."
  default     = []
}

# =============================================================================
# Default (System) Node Pool
# =============================================================================

variable "node_vm_size" {
  type        = string
  description = "VM size for nodes in the system (default) node pool."
}

variable "node_count" {
  type        = number
  description = "Initial node count for the system pool. Ignored when enable_auto_scaling = true."
  default     = 1
}

variable "enable_auto_scaling" {
  type        = bool
  description = "Enable cluster autoscaler on the system node pool."
  default     = false
}

variable "min_node_count" {
  type        = number
  description = "Minimum node count when autoscaling is enabled."
  default     = 1
}

variable "max_node_count" {
  type        = number
  description = "Maximum node count when autoscaling is enabled."
  default     = 3
}

variable "only_critical_addons_enabled" {
  type        = bool
  description = "Taint the system pool with CriticalAddonsOnly=true:NoSchedule so only system workloads are scheduled there."
  default     = false
}

variable "temporary_name_for_rotation" {
  type        = string
  description = "Temporary node pool name used during rotation when changing immutable properties (e.g. vm_size). Set to null when not rotating."
  default     = null
}

variable "node_upgrade_max_surge" {
  type        = string
  description = "Max surge for node pool upgrades (e.g. '10%' or an integer count)."
  default     = null
}

variable "node_upgrade_drain_timeout_minutes" {
  type        = number
  description = "Drain timeout in minutes during node upgrades."
  default     = null
}

variable "node_upgrade_soak_duration_minutes" {
  type        = number
  description = "Soak duration in minutes after a node is upgraded before proceeding."
  default     = null
}

variable "node_pool_availability_zones" {
  type        = list(string)
  description = "Availability zones for all node pools (e.g. ['1', '2', '3'])."
  default     = null
}

variable "node_pool_max_pods" {
  type        = number
  description = "Maximum pods per node in the system pool."
  default     = 30
}

variable "node_pool_os_disk_size_gb" {
  type        = number
  description = "OS disk size in GB for the system pool."
  default     = 128
}

variable "node_pool_os_disk_type" {
  type        = string
  description = "OS disk type: Managed or Ephemeral."
  default     = "Managed"
}

variable "node_labels" {
  type        = map(string)
  description = "Labels applied to nodes in the system pool."
  default     = {}
}

variable "host_encryption_enabled" {
  type        = bool
  description = "Enable host-based encryption for temp disk and cached data at rest."
  default     = false
}

# =============================================================================
# Worker Node Pools (includes GPU Spot and CPU Spot burst)
# =============================================================================

variable "worker_node_pools" {
  type = list(object({
    name                        = string
    vm_size                     = string
    node_count                  = optional(number, 1)
    mode                        = optional(string, "User")
    os_type                     = optional(string, "Linux")
    auto_scaling_enabled        = optional(bool, true)
    host_encryption_enabled     = optional(bool, false)
    temporary_name_for_rotation = optional(string, null)
    min_count                   = optional(number, 1)
    max_count                   = optional(number, 3)
    max_pods                    = optional(number, 110)
    os_disk_size_gb             = optional(number, 128)
    workload_runtime            = optional(string, "OCIContainer")
    node_labels                 = optional(map(string), {})
    node_taints                 = optional(list(string), [])
    max_surge                   = optional(string, "10%")
    drain_timeout_minutes       = optional(number, 0)
    soak_duration_minutes       = optional(number, 0)
    # Spot-specific fields
    priority        = optional(string, "Regular") # "Regular" or "Spot"
    eviction_policy = optional(string, "Delete")  # "Delete" — used only when priority = "Spot"
    spot_max_price  = optional(number, -1)        # -1 = current Azure market price
  }))
  description = "Additional worker node pools. Set priority = 'Spot' for GPU Spot or CPU Spot burst pools."
  default     = []

  validation {
    condition = alltrue([
      for np in var.worker_node_pools :
      contains(["Regular", "Spot"], np.priority)
    ])
    error_message = "Each worker_node_pools entry must have priority set to 'Regular' or 'Spot'."
  }

  validation {
    condition = alltrue([
      for np in var.worker_node_pools :
      contains(["User", "System"], np.mode)
    ])
    error_message = "Each worker_node_pools entry must have mode set to 'User' or 'System'."
  }
}

# =============================================================================
# Network Configuration
# =============================================================================

variable "network_plugin" {
  type        = string
  description = "Network plugin: azure (Azure CNI) or kubenet."
  default     = "azure"

  validation {
    condition     = contains(["azure", "kubenet"], var.network_plugin)
    error_message = "network_plugin must be 'azure' or 'kubenet'."
  }
}

variable "network_plugin_mode" {
  type        = string
  description = "Network plugin mode: 'overlay' for Azure CNI Overlay, or null for standard Azure CNI."
  default     = null

  validation {
    condition     = var.network_plugin_mode == null ? true : contains(["overlay"], var.network_plugin_mode)
    error_message = "network_plugin_mode must be 'overlay' or null."
  }
}

variable "network_policy" {
  type        = string
  description = "Network policy engine: azure, calico, or null."
  default     = null
}

variable "vnet_subnet_id" {
  type        = string
  description = "Subnet ID for AKS nodes (required for Azure CNI). All node pools share this subnet."
  default     = null
}

variable "api_server_authorized_ip_ranges" {
  type        = list(string)
  description = "List of CIDRs authorized to reach the AKS API server (public clusters only). Set null to allow all — acceptable for dev; restrict to VPN/office CIDRs for production."
  default     = null
}

variable "service_cidr" {
  type        = string
  description = "CIDR for Kubernetes services. Must not overlap with VNet address space."
  default     = "10.100.0.0/16"
}

variable "dns_service_ip" {
  type        = string
  description = "IP address for the Kubernetes DNS service (must be within service_cidr)."
  default     = "10.100.0.10"
}

variable "outbound_type" {
  type        = string
  description = "Outbound routing method: loadBalancer, userDefinedRouting, or managedNATGateway."
  default     = "loadBalancer"
}

variable "enable_private_cluster" {
  type        = bool
  description = "Enable private cluster (API server not publicly accessible)."
  default     = false
}

variable "private_dns_zone_id" {
  type        = string
  description = "Private DNS zone ID for private cluster. Required when enable_private_cluster = true."
  default     = null
}

# =============================================================================
# Security & Identity
# =============================================================================

variable "enable_azure_rbac" {
  type        = bool
  description = "Enable Azure RBAC for Kubernetes authorization."
  default     = true
}

variable "enable_azure_ad" {
  type        = bool
  description = "Enable Azure AD/Entra ID integration."
  default     = true
}

variable "azure_ad_admin_group_ids" {
  type        = list(string)
  description = "Azure AD group IDs for cluster admin access."
  default     = []
}

variable "enable_key_vault_secrets_provider" {
  type        = bool
  description = "Enable Azure Key Vault Secrets Provider CSI driver."
  default     = false
}

variable "secret_rotation_enabled" {
  type        = bool
  description = "Enable automatic secret rotation in the Key Vault CSI driver."
  default     = true
}

variable "enable_workload_identity" {
  type        = bool
  description = "Enable workload identity for pod-managed identities."
  default     = false
}

variable "oidc_issuer_enabled" {
  type        = bool
  description = "Enable OIDC issuer (required for workload identity)."
  default     = false
}

# =============================================================================
# ACR Integration
# =============================================================================

variable "acr_id" {
  type        = string
  description = "Resource ID of the Azure Container Registry to grant AcrPull."
  default     = null
}

variable "enable_acr" {
  type        = bool
  description = "Whether ACR exists (passed from the stack) so the role assignment is conditionally created."
  default     = true
}

variable "enable_acr_pull_role" {
  type        = bool
  description = "Toggle creation of the AcrPull role assignment on the kubelet identity."
  default     = true
}

# =============================================================================
# Monitoring & Observability
# =============================================================================

variable "enable_azure_monitor" {
  type        = bool
  description = "Enable Azure Monitor Container Insights (OMS agent)."
  default     = false
}

variable "log_analytics_workspace_id" {
  type        = string
  description = "Log Analytics Workspace ID for Container Insights and Defender."
  default     = null
}

variable "enable_diagnostic_settings" {
  type        = bool
  description = "Enable diagnostic settings to forward AKS control plane logs to Log Analytics."
  default     = false
}

variable "enable_metric_alerts" {
  type        = bool
  description = "Enable CPU and memory metric alerts."
  default     = false
}

variable "action_group_id" {
  type        = string
  description = "Action group ID for metric alert notifications."
  default     = null
}

variable "alert_cpu_threshold" {
  type        = number
  description = "CPU usage percentage threshold that triggers an alert."
  default     = 80
}

variable "alert_memory_threshold" {
  type        = number
  description = "Memory working-set percentage threshold that triggers an alert."
  default     = 80
}

# =============================================================================
# Add-ons
# =============================================================================

variable "enable_azure_policy" {
  type        = bool
  description = "Enable Azure Policy add-on."
  default     = false
}

variable "enable_web_app_routing" {
  type        = bool
  description = "Enable Web App Routing (Application Routing add-on) for managed nginx ingress."
  default     = false
}

variable "web_app_routing_dns_zone_ids" {
  type        = list(string)
  description = "DNS zone resource IDs for automatic DNS integration with Web App Routing."
  default     = []
}

variable "enable_http_application_routing" {
  type        = bool
  description = "Enable HTTP application routing add-on (deprecated — prefer web_app_routing)."
  default     = false
}

variable "image_cleaner_enabled" {
  type        = bool
  description = "Enable Image Cleaner to automatically remove unused container images from nodes."
  default     = false
}

variable "image_cleaner_interval_hours" {
  type        = number
  description = "Interval in hours for Image Cleaner runs."
  default     = 48
}

variable "keda_enabled" {
  type        = bool
  description = "Enable KEDA (Kubernetes Event-driven Autoscaling) add-on."
  default     = false
}

variable "vertical_pod_autoscaler_enabled" {
  type        = bool
  description = "Enable Vertical Pod Autoscaler to auto-adjust pod resource requests."
  default     = false
}

variable "microsoft_defender_enabled" {
  type        = bool
  description = "Enable Microsoft Defender for Containers runtime security scanning."
  default     = false
}

# =============================================================================
# Autoscaler Profile
# =============================================================================

variable "auto_scaler_profile" {
  type = object({
    expander                     = optional(string, "least-waste")
    balance_similar_node_groups  = optional(bool, false)
    max_graceful_termination_sec = optional(number, 600)
    scale_down_delay_after_add   = optional(string, "10m")
    scale_down_unneeded          = optional(string, "10m")
    scan_interval                = optional(string, "10s")
  })
  description = "Cluster autoscaler profile tunables. Null uses AKS defaults."
  default     = null
}

# =============================================================================
# Maintenance Windows
# =============================================================================

variable "maintenance_window" {
  type = object({
    day_of_week  = string
    start_hour   = number
    start_minute = number
    duration     = number
  })
  description = "Basic maintenance window (allowed/not-allowed day and hour blocks)."
  default     = null
}

variable "maintenance_window_auto_upgrade" {
  type = object({
    frequency    = string
    interval     = number
    duration     = number
    day_of_week  = optional(string)
    day_of_month = optional(number)
    week_index   = optional(string)
    start_time   = optional(string)
    utc_offset   = optional(string)
    start_date   = optional(string)
    not_allowed = optional(list(object({
      start = string
      end   = string
    })))
  })
  description = "Maintenance window for automatic Kubernetes control-plane upgrades."
  default     = null
}

variable "maintenance_window_node_os" {
  type = object({
    frequency    = string
    interval     = number
    duration     = number
    day_of_week  = optional(string)
    day_of_month = optional(number)
    week_index   = optional(string)
    start_time   = optional(string)
    utc_offset   = optional(string)
    start_date   = optional(string)
    not_allowed = optional(list(object({
      start = string
      end   = string
    })))
  })
  description = "Maintenance window for node OS security patching."
  default     = null
}
