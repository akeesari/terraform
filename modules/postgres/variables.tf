variable "name" {
  type        = string
  description = "PostgreSQL flexible server name (lowercase, unique in region)."
}
variable "resource_group_name" {
  type        = string
  description = "Target Azure resource group name."
}
variable "location" {
  type        = string
  description = "Azure region for the PostgreSQL server."
}
variable "admin_login" {
  type        = string
  description = "Administrator login name for the server."
}
variable "admin_password" {
  type        = string
  description = "Administrator password for the server."
  sensitive   = true
}
variable "sku_name" {
  type        = string
  description = "SKU name (e.g., GP_Standard_D2s_v3)."
}
variable "storage_mb" {
  type        = number
  description = "Allocated storage size in MB."
}
variable "server_version" {
  type        = string
  description = "PostgreSQL engine version (e.g., 14, 15)."
}
variable "backup_retention_days" {
  type        = number
  description = "Backup retention in days (Azure allows 7-35)."
}
variable "public_network_access_enabled" {
  type        = bool
  description = "Enable public network access. Defaults to false; set to true only in dev when no private endpoint is used."
  default     = false
}

variable "databases" {
  type = list(object({
    name   = string
    create = optional(bool, true)
  }))
  description = "List of databases to create on the PostgreSQL server"
  default     = []
}

variable "db_charset" {
  type        = string
  description = "Database character set (e.g., UTF8)."
  default     = "UTF8"
}

variable "db_collation" {
  type        = string
  description = "Database collation (e.g., en_US.utf8)."
  default     = "en_US.utf8"
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to the server resource."
  default     = {}
}
variable "enable_postgres_server" {
  type        = bool
  description = "Toggle creation of PostgreSQL server"
  default     = true
}

variable "enable_cmk" {
  type        = bool
  description = "Enable Customer-Managed Key (CMK) encryption. When true, a system-assigned managed identity is added and Key Vault integration is expected."
  default     = false
}

variable "enable_entra_auth" {
  type        = bool
  description = "Enable Microsoft Entra ID (Azure AD) authentication on the server."
  default     = false
}

variable "enable_password_auth" {
  type        = bool
  description = "Enable password-based authentication. Set to false (with enable_entra_auth = true) for Entra-only access."
  default     = true
}

variable "delegated_subnet_id" {
  type        = string
  description = "Delegated subnet ID for private endpoint integration"
  default     = null
}

variable "private_dns_zone_id" {
  type        = string
  description = "Private DNS zone ID for PostgreSQL (required for private access)"
  default     = null
}

variable "geo_redundant_backup_enabled" {
  type        = bool
  description = "Enable geo-redundant backups"
  default     = false
}

variable "auto_grow_enabled" {
  type        = bool
  description = "Enable storage auto-grow"
  default     = true
}

variable "zone" {
  type        = string
  description = "Availability zone for the server (1, 2, or 3)"
  default     = null
}

variable "high_availability_mode" {
  type        = string
  description = "High availability mode: ZoneRedundant or SameZone (requires zone to be set)"
  default     = null
}

variable "standby_availability_zone" {
  type        = string
  description = "Availability zone for standby server (required for ZoneRedundant HA)"
  default     = null
}

variable "maintenance_window" {
  type = object({
    day_of_week  = number
    start_hour   = number
    start_minute = number
  })
  description = "Maintenance window configuration (day_of_week: 0=Sunday, start_hour: 0-23, start_minute: 0-59)"
  default     = null
}

# =============================================================================
# Monitoring Alerts
# =============================================================================

variable "enable_metric_alerts" {
  type        = bool
  description = "Enable metric alerts for PostgreSQL"
  default     = false
}

variable "action_group_id" {
  type        = string
  description = "Action group ID for metric alert notifications"
  default     = null
}

variable "alert_cpu_threshold" {
  type        = number
  description = "CPU percentage threshold for alerting"
  default     = 80
}

variable "alert_memory_threshold" {
  type        = number
  description = "Memory percentage threshold for alerting"
  default     = 80
}

variable "alert_storage_threshold" {
  type        = number
  description = "Storage percentage threshold for alerting"
  default     = 85
}

variable "alert_connection_failures_threshold" {
  type        = number
  description = "Connection failures threshold for alerting"
  default     = 10
}
