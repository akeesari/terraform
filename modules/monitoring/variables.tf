variable "name" {
  type        = string
  description = "Log Analytics Workspace name."
  validation {
    condition     = length(var.name) >= 4 && length(var.name) <= 63
    error_message = "Log Analytics Workspace name must be 4–63 characters."
  }
}

variable "resource_group_name" {
  type        = string
  description = "Resource group in which to create the workspace."
}

variable "location" {
  type        = string
  description = "Azure region for the workspace."
}

variable "sku" {
  type        = string
  description = "Pricing SKU. PerGB2018 is the standard pay-per-use SKU."
  default     = "PerGB2018"
  validation {
    condition     = contains(["Free", "PerGB2018", "CapacityReservation"], var.sku)
    error_message = "sku must be Free, PerGB2018, or CapacityReservation."
  }
}

variable "retention_in_days" {
  type        = number
  description = "Data retention period in days (7–730; Free tier is fixed at 7)."
  default     = 30
  validation {
    condition     = var.retention_in_days >= 7 && var.retention_in_days <= 730
    error_message = "retention_in_days must be 7–730."
  }
}

variable "daily_quota_gb" {
  type        = number
  description = "Daily ingestion cap in GB. -1 = unlimited. Dev: 1, Prod: 20."
  default     = -1
}

variable "enable_log_analytics" {
  type        = bool
  description = "Set to false to skip creating the Log Analytics Workspace."
  default     = true
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to all resources."
  default     = {}
}

# ---------------------------------------------------------------------------
# Application Insights
# ---------------------------------------------------------------------------

variable "enable_application_insights" {
  type        = bool
  description = "Create a workspace-based Application Insights instance backed by the Log Analytics Workspace."
  default     = false
}

variable "app_insights_name" {
  type        = string
  description = "Application Insights resource name. Defaults to '<name>-appins' when not set."
  default     = null
}

# ---------------------------------------------------------------------------
# Alerts / Action Group
# ---------------------------------------------------------------------------

variable "enable_alerts" {
  type        = bool
  description = "Create a Monitor Action Group for alert notifications."
  default     = false
}

variable "alert_email_addresses" {
  type        = list(string)
  description = "Email addresses that receive alert notifications. Required when enable_alerts = true."
  default     = []
}

variable "action_group_name" {
  type        = string
  description = "Monitor Action Group name. Defaults to '<name>-ag' when not set."
  default     = null
}

variable "action_group_short_name" {
  type        = string
  description = "Short name for the action group (max 12 characters)."
  default     = "alerts"
  validation {
    condition     = length(var.action_group_short_name) <= 12
    error_message = "action_group_short_name must be 12 characters or fewer."
  }
}
