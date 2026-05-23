variable "name" {
  type        = string
  description = "SQL Server logical name (globally unique, 1–63 lowercase alphanumeric and hyphens)."
  validation {
    condition     = can(regex("^[a-z0-9-]{1,63}$", var.name))
    error_message = "SQL Server name must be 1–63 lowercase alphanumeric characters or hyphens."
  }
}

variable "resource_group_name" {
  type        = string
  description = "Resource group that will contain the SQL Server."
}

variable "location" {
  type        = string
  description = "Azure region for the SQL Server."
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to all resources in this module."
  default     = {}
}

variable "enable_sql_server" {
  type        = bool
  description = "Toggle creation of the SQL Server and all child resources."
  default     = true
}

variable "sql_version" {
  type        = string
  description = "SQL Server version. Only 12.0 is currently supported."
  default     = "12.0"
}

# ---------------------------------------------------------------------------
# Authentication
# ---------------------------------------------------------------------------

variable "administrator_login" {
  type        = string
  description = "SQL administrator login name (ignored when azuread_authentication_only = true)."
  default     = "sqladmin"
}

variable "administrator_login_password" {
  type        = string
  description = "SQL administrator password (ignored when azuread_authentication_only = true)."
  sensitive   = true
  default     = null
}

variable "azuread_admin_login" {
  type        = string
  description = "Azure AD administrator login username."
  default     = null
}

variable "azuread_admin_object_id" {
  type        = string
  description = "Azure AD administrator object ID."
  default     = null
}

variable "azuread_admin_tenant_id" {
  type        = string
  description = "Azure AD tenant ID for the administrator (defaults to current tenant)."
  default     = null
}

variable "azuread_authentication_only" {
  type        = bool
  description = "When true, only Azure AD authentication is permitted (disables SQL auth)."
  default     = false
}

# ---------------------------------------------------------------------------
# Network Access
# ---------------------------------------------------------------------------

variable "public_network_access_enabled" {
  type        = bool
  description = "Allow public internet access to the SQL Server. Set false for private-only deployments."
  default     = false
}

variable "allow_azure_services" {
  type        = bool
  description = "Allow Azure-internal services to bypass the firewall (0.0.0.0–0.0.0.0 rule). WARNING: this permits ALL Azure-hosted services, not just yours. Leave false in production and use Private Endpoints instead."
  default     = false
}

variable "firewall_rules" {
  type = list(object({
    name             = string
    start_ip_address = string
    end_ip_address   = string
  }))
  description = "Custom firewall allow rules. Each rule must have a unique name."
  default     = []
}

# ---------------------------------------------------------------------------
# Databases
# ---------------------------------------------------------------------------

variable "databases" {
  type = list(object({
    name           = string
    sku_name       = optional(string, "S0")
    max_size_gb    = optional(number, 250)
    collation      = optional(string, "SQL_Latin1_General_CP1_CI_AS")
    zone_redundant = optional(bool, false)
  }))
  description = "List of databases to create on the SQL Server."
  default     = []
}
