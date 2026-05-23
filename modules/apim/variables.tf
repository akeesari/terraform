variable "name" {
  type        = string
  description = "API Management service name (globally unique, 1–50 characters, letters, numbers, and hyphens)."

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9-]{0,48}[a-zA-Z0-9]$", var.name))
    error_message = "API Management service name must be 1–50 characters, start with a letter, and contain only letters, numbers, and hyphens."
  }
}

variable "resource_group_name" {
  type        = string
  description = "Resource group to place the API Management service in."
}

variable "location" {
  type        = string
  description = "Azure region."
}

variable "publisher_name" {
  type        = string
  description = "Name of the API publisher shown in the developer portal and outbound emails."
}

variable "publisher_email" {
  type        = string
  description = "Email address of the API publisher. Receives system notifications."

  validation {
    condition     = can(regex("^[^@]+@[^@]+\\.[^@]+$", var.publisher_email))
    error_message = "publisher_email must be a valid email address."
  }
}

variable "sku_name" {
  type        = string
  description = "SKU name and unit count in '<tier>_<units>' format. Examples: Developer_1, Basic_1, Standard_1, Premium_1, Consumption_0. Developer and Consumption are not suitable for production SLAs."
  default     = "Standard_1"

  validation {
    condition     = can(regex("^(Consumption|Developer|Basic|Standard|Premium)_[0-9]+$", var.sku_name))
    error_message = "sku_name must be in '<tier>_<units>' format, e.g. Developer_1, Standard_1, Premium_2."
  }
}

# ---------------------------------------------------------------------------
# VNet integration
# ---------------------------------------------------------------------------

variable "virtual_network_type" {
  type        = string
  description = "VNet integration mode. 'None' = public only. 'External' = public + VNet inbound. 'Internal' = VNet-only (requires Premium SKU or Developer)."
  default     = "None"

  validation {
    condition     = contains(["None", "External", "Internal"], var.virtual_network_type)
    error_message = "virtual_network_type must be None, External, or Internal."
  }
}

variable "min_api_version" {
  type        = string
  description = "Minimum API Management REST API version clients must use. Example: '2019-12-01'. Null disables the restriction."
  default     = null
}

variable "subnet_id" {
  type        = string
  description = "Subnet resource ID for VNet integration. Required when virtual_network_type is External or Internal. The subnet must be delegated to Microsoft.ApiManagement/service."
  default     = null
}

# ---------------------------------------------------------------------------
# Observability
# ---------------------------------------------------------------------------

variable "log_analytics_workspace_id" {
  type        = string
  description = "Log Analytics Workspace resource ID. When set, GatewayLogs and AllMetrics are streamed to this workspace."
  default     = null
}

variable "app_insights_id" {
  type        = string
  description = "Application Insights resource ID. Required together with app_insights_instrumentation_key to enable the APIM logger."
  default     = null
}

variable "app_insights_instrumentation_key" {
  type        = string
  description = "Application Insights instrumentation key. Required together with app_insights_id to enable the APIM logger."
  sensitive   = true
  default     = null
}

# ---------------------------------------------------------------------------
# Named Values
# ---------------------------------------------------------------------------

variable "named_values" {
  type = list(object({
    name         = string
    display_name = string
    value        = string
    secret       = optional(bool, false)
  }))
  description = "Named values (config key-value pairs) accessible inside APIM policies via {{name}} syntax. Set secret = true for sensitive values — they are masked in the portal."
  default     = []
}

# ---------------------------------------------------------------------------
# Management Lock
# ---------------------------------------------------------------------------

variable "enable_management_lock" {
  type        = bool
  description = "Create a CanNotDelete management lock to guard against accidental deletion."
  default     = false
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to all resources."
  default     = {}
}
