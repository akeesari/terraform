variable "name" {
  type        = string
  description = "Cosmos DB account name (3–44 chars, globally unique, lowercase alphanumeric and hyphens)."

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{1,42}[a-z0-9]$", var.name))
    error_message = "name must be 3–44 chars, start/end with lowercase alphanumeric, and contain only lowercase alphanumeric and hyphens."
  }
}

variable "resource_group_name" {
  type        = string
  description = "Resource group to place the Cosmos DB account in."
}

variable "location" {
  type        = string
  description = "Primary Azure region for the Cosmos DB account (write region)."
}

variable "kind" {
  type        = string
  description = "Cosmos DB API kind: GlobalDocumentDB (Core/SQL), MongoDB, or Parse."
  default     = "GlobalDocumentDB"

  validation {
    condition     = contains(["GlobalDocumentDB", "MongoDB", "Parse"], var.kind)
    error_message = "kind must be GlobalDocumentDB, MongoDB, or Parse."
  }
}

variable "consistency_level" {
  type        = string
  description = "Default consistency level: Eventual, ConsistentPrefix, Session, BoundedStaleness, or Strong."
  default     = "Session"

  validation {
    condition     = contains(["Eventual", "ConsistentPrefix", "Session", "BoundedStaleness", "Strong"], var.consistency_level)
    error_message = "consistency_level must be one of: Eventual, ConsistentPrefix, Session, BoundedStaleness, or Strong."
  }
}

variable "max_interval_in_seconds" {
  type        = number
  description = "BoundedStaleness: maximum staleness window in seconds (5–86400). Ignored for other consistency levels."
  default     = 300
}

variable "max_staleness_prefix" {
  type        = number
  description = "BoundedStaleness: maximum number of stale requests tolerated (10–2147483647). Ignored for other consistency levels."
  default     = 100000
}

variable "zone_redundant" {
  type        = bool
  description = "Enable availability zone redundancy for the primary write region."
  default     = false
}

variable "enable_automatic_failover" {
  type        = bool
  description = "Automatically promote a read region to the write region if the primary fails."
  default     = true
}

variable "enable_multi_write_locations" {
  type        = bool
  description = "Enable active-active multi-region writes. Requires enable_automatic_failover = true."
  default     = false
}

variable "public_network_access_enabled" {
  type        = bool
  description = "Allow public network access. Set to false when using private endpoints."
  default     = false
}

variable "enable_analytical_storage" {
  type        = bool
  description = "Enable Azure Synapse Link (analytical store) on the account."
  default     = false
}

variable "failover_locations" {
  type = list(object({
    location          = string
    failover_priority = number
    zone_redundant    = optional(bool)
  }))
  description = "Additional read / failover regions. failover_priority must start at 1 and be unique per region."
  default     = []
}

variable "backup_type" {
  type        = string
  description = "Backup type: Periodic (configurable schedule) or Continuous (point-in-time restore)."
  default     = "Periodic"

  validation {
    condition     = contains(["Continuous", "Periodic"], var.backup_type)
    error_message = "backup_type must be Continuous or Periodic."
  }
}

variable "continuous_backup_tier" {
  type        = string
  description = "Continuous backup tier: Continuous7Days or Continuous30Days. Only used when backup_type = Continuous."
  default     = "Continuous7Days"

  validation {
    condition     = contains(["Continuous7Days", "Continuous30Days"], var.continuous_backup_tier)
    error_message = "continuous_backup_tier must be Continuous7Days or Continuous30Days."
  }
}

variable "backup_interval_in_minutes" {
  type        = number
  description = "Periodic backup interval in minutes (60–1440). Only used when backup_type = Periodic."
  default     = 240
}

variable "backup_retention_in_hours" {
  type        = number
  description = "Periodic backup retention in hours (8–720). Only used when backup_type = Periodic."
  default     = 168
}

variable "backup_storage_redundancy" {
  type        = string
  description = "Periodic backup storage redundancy: Geo, Local, or Zone. Only used when backup_type = Periodic."
  default     = "Geo"

  validation {
    condition     = contains(["Geo", "Local", "Zone"], var.backup_storage_redundancy)
    error_message = "backup_storage_redundancy must be Geo, Local, or Zone."
  }
}

variable "databases" {
  type = map(object({
    throughput     = optional(number) # manual throughput; null = use autoscale or serverless
    max_throughput = optional(number) # autoscale max; null = use manual throughput or serverless
    containers = optional(map(object({
      partition_key_path     = string
      partition_key_version  = optional(number, 2)
      throughput             = optional(number)
      max_throughput         = optional(number)
      default_ttl            = optional(number)     # seconds; -1 = delete on TTL expiry; null = disabled
      analytical_storage_ttl = optional(number, -1) # -1 = infinite retention in analytical store
    })), {})
  }))
  description = "SQL databases to create. Key = database name. Each database can nest containers. Set max_throughput for autoscale, throughput for manual, or omit both for serverless."
  default     = {}
}

# ---------------------------------------------------------------------------
# Management Lock
# ---------------------------------------------------------------------------

variable "enable_management_lock" {
  type        = bool
  description = "Create a CanNotDelete management lock on the Cosmos DB account. Set true in prod."
  default     = false
}

# ---------------------------------------------------------------------------
# Metric Alerts
# ---------------------------------------------------------------------------

variable "enable_metric_alerts" {
  type        = bool
  description = "Enable metric alerts for RU consumption and throttled requests."
  default     = false
}

variable "action_group_id" {
  type        = string
  description = "Monitor Action Group ID for alert notifications. Required when enable_metric_alerts = true."
  default     = null
}

variable "alert_ru_threshold" {
  type        = number
  description = "Normalized RU consumption percentage threshold that triggers an alert (0–100)."
  default     = 80

  validation {
    condition     = var.alert_ru_threshold > 0 && var.alert_ru_threshold <= 100
    error_message = "alert_ru_threshold must be between 1 and 100."
  }
}

variable "alert_throttled_requests_threshold" {
  type        = number
  description = "Count of 429 throttled requests per 15-minute window that triggers an alert."
  default     = 10
}

# ---------------------------------------------------------------------------
# Managed Identity
# ---------------------------------------------------------------------------

variable "identity_type" {
  type        = string
  description = "Managed identity type: SystemAssigned, UserAssigned, or 'SystemAssigned, UserAssigned'. Null disables identity."
  default     = null

  validation {
    condition     = var.identity_type == null || contains(["SystemAssigned", "UserAssigned", "SystemAssigned, UserAssigned"], var.identity_type)
    error_message = "identity_type must be SystemAssigned, UserAssigned, 'SystemAssigned, UserAssigned', or null."
  }
}

variable "user_assigned_identity_ids" {
  type        = list(string)
  description = "Resource IDs of user-assigned managed identities. Required when identity_type includes UserAssigned."
  default     = []
}

# ---------------------------------------------------------------------------
# Customer-Managed Key (CMK)
# ---------------------------------------------------------------------------

variable "key_vault_key_id" {
  type        = string
  description = "Key Vault key URI for customer-managed encryption at rest. Requires identity_type to be set."
  default     = null
}

# ---------------------------------------------------------------------------
# API Capabilities
# ---------------------------------------------------------------------------

variable "enable_free_tier" {
  type        = bool
  description = "Enable free tier (400 RU/s + 25 GB free). Only one Cosmos DB account per subscription can use free tier."
  default     = false
}

variable "additional_capabilities" {
  type        = list(string)
  description = "Additional Cosmos DB capability names to enable (e.g. EnableServerless). EnableMongo is injected automatically when kind = MongoDB."
  default     = []
}

# ---------------------------------------------------------------------------
# VNet Filtering
# ---------------------------------------------------------------------------

variable "is_virtual_network_filter_enabled" {
  type        = bool
  description = "Enable VNet service endpoint filtering on the Cosmos DB account."
  default     = false
}

variable "ip_range_filter" {
  type        = list(string)
  description = "List of IP address CIDRs allowed to access the account when VNet filtering is enabled."
  default     = []
}

variable "virtual_network_rules" {
  type = list(object({
    id                                   = string
    ignore_missing_vnet_service_endpoint = optional(bool, false)
  }))
  description = "VNet subnet IDs allowed to access the Cosmos DB account via service endpoints."
  default     = []
}

# ---------------------------------------------------------------------------
# Private Endpoint
# ---------------------------------------------------------------------------

variable "enable_private_endpoints" {
  type        = bool
  description = "Restrict public access and provision a private endpoint. Set public_network_access_enabled = false alongside this."
  default     = false
}

variable "private_endpoint_subnet_id" {
  type        = string
  description = "Subnet ID for the Cosmos DB private endpoint NIC. Required when enable_private_endpoints = true."
  default     = null
}

variable "private_endpoint_subresource_name" {
  type        = string
  description = "Private endpoint sub-resource type: Sql, MongoDB, Cassandra, Gremlin, or Table."
  default     = "Sql"

  validation {
    condition     = contains(["Sql", "MongoDB", "Cassandra", "Gremlin", "Table"], var.private_endpoint_subresource_name)
    error_message = "private_endpoint_subresource_name must be one of: Sql, MongoDB, Cassandra, Gremlin, Table."
  }
}

variable "cosmos_db_dns_zone_id" {
  type        = string
  description = "Private DNS zone resource ID for Cosmos DB DNS resolution. Required when enable_private_endpoints = true."
  default     = null
}

# ---------------------------------------------------------------------------
# Diagnostic Settings
# ---------------------------------------------------------------------------

variable "enable_diagnostic_settings" {
  type        = bool
  description = "Enable diagnostic settings to stream logs and metrics to a Log Analytics workspace."
  default     = false
}

variable "log_analytics_workspace_id" {
  type        = string
  description = "Log Analytics workspace resource ID for diagnostic logs. Required when enable_diagnostic_settings = true."
  default     = null
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to all Cosmos DB resources."
  default     = {}
}
