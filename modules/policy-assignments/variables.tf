variable "enable_policy" {
  description = "Set to true to provision all policy assignments and role assignments."
  type        = bool
  default     = false
}

variable "subscription_id" {
  description = "Azure subscription ID."
  type        = string
  validation {
    condition     = can(regex("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", var.subscription_id))
    error_message = "subscription_id must be a valid UUID."
  }
}

variable "location" {
  description = "Primary Azure region for DINE/Modify policy managed identities."
  type        = string
}

variable "allowed_locations" {
  description = "List of allowed Azure regions for resource deployment."
  type        = list(string)
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace resource ID for Activity Log diagnostics."
  type        = string
}

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
  default     = {}
}
