variable "name" {
  type        = string
  description = "App Service Plan name (primary resource name)."
}

variable "resource_group_name" {
  type        = string
  description = "Resource group that will contain all App Service resources."
}

variable "location" {
  type        = string
  description = "Azure region for all App Service resources."
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to all resources in this module."
  default     = {}
}

variable "sku_name" {
  type        = string
  description = "App Service Plan SKU (e.g. B1, B3, P1v3, P2v3)."
  default     = "B1"

  validation {
    condition     = contains(["B1", "B2", "B3", "S1", "S2", "S3", "P1v2", "P2v2", "P3v2", "P1v3", "P2v3", "P3v3", "P1mv3", "P2mv3", "P3mv3", "P4mv3", "P5mv3"], var.sku_name)
    error_message = "sku_name must be a valid App Service Plan SKU (e.g. B1, P1v3, P2v3)."
  }
}

variable "client_affinity_enabled" {
  type        = bool
  description = "Enable session affinity (sticky sessions) so the load balancer routes repeat requests from the same client to the same instance. Disable for stateless apps."
  default     = false
}

variable "environment" {
  type        = string
  description = "Deployment environment identifier injected as an app setting (e.g. dev, test, prod)."
}

variable "common_app_settings" {
  type        = map(string)
  description = "Additional app settings merged with the auto-generated App Insights settings."
  default     = {}
}

# ---------------------------------------------------------------------------
# Feature Toggles
# ---------------------------------------------------------------------------

variable "enable_plan" {
  type        = bool
  description = "Toggle creation of the App Service Plan. Disabling also suppresses web/api apps."
  default     = true
}

variable "enable_app_insights" {
  type        = bool
  description = "Toggle creation of Application Insights."
  default     = true
}

variable "enable_web_app" {
  type        = bool
  description = "Toggle creation of the primary Linux web app."
  default     = true
}

variable "enable_api_app" {
  type        = bool
  description = "Toggle creation of the secondary Linux API app."
  default     = false
}

# ---------------------------------------------------------------------------
# Application Insights
# ---------------------------------------------------------------------------

variable "app_insights_name" {
  type        = string
  description = "Application Insights resource name. Required when enable_app_insights = true."
  default     = null
}

variable "log_analytics_workspace_id" {
  type        = string
  description = "Log Analytics workspace resource ID to back Application Insights (workspace-based). Null creates a classic instance."
  default     = null
}

# ---------------------------------------------------------------------------
# Web App Names
# ---------------------------------------------------------------------------

variable "web_app_name" {
  type        = string
  description = "Primary Linux web app name (globally unique). Required when enable_web_app = true."
  default     = ""
}

variable "api_app_name" {
  type        = string
  description = "Secondary Linux API app name (globally unique). Required when enable_api_app = true."
  default     = ""
}
