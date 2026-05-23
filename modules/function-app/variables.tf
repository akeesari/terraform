variable "name" {
  type        = string
  description = "Function App name (globally unique, 2–60 characters)."

  validation {
    condition     = can(regex("^[a-zA-Z0-9][a-zA-Z0-9-]{0,58}[a-zA-Z0-9]$", var.name))
    error_message = "Function App name must be 2–60 characters and contain only letters, numbers, and hyphens."
  }
}

variable "resource_group_name" {
  type        = string
  description = "Resource group to place the Function App and its backing resources in."
}

variable "location" {
  type        = string
  description = "Azure region."
}

variable "storage_account_name" {
  type        = string
  description = "Storage account name for the Functions runtime backing store (3–24 lowercase alphanumeric, globally unique)."

  validation {
    condition     = can(regex("^[a-z0-9]{3,24}$", var.storage_account_name))
    error_message = "Storage account name must be 3–24 lowercase alphanumeric characters with no hyphens."
  }
}

# ---------------------------------------------------------------------------
# Service Plan
# ---------------------------------------------------------------------------

variable "sku_name" {
  type        = string
  description = "App Service Plan SKU. Use EP1/EP2/EP3 for Premium (always warm, VNet support) or Y1 for Consumption (cold starts, no VNet)."
  default     = "EP1"

  validation {
    condition     = contains(["Y1", "EP1", "EP2", "EP3"], var.sku_name)
    error_message = "sku_name must be Y1 (Consumption), EP1, EP2, or EP3 (Premium)."
  }
}

# ---------------------------------------------------------------------------
# Runtime
# ---------------------------------------------------------------------------

variable "runtime_stack" {
  type        = string
  description = "Function runtime: python, node, dotnet, java, or powershell."

  validation {
    condition     = contains(["python", "node", "dotnet", "java", "powershell"], var.runtime_stack)
    error_message = "runtime_stack must be one of: python, node, dotnet, java, powershell."
  }
}

variable "runtime_version" {
  type        = string
  description = "Runtime version string. Examples: python → '3.11', node → '20', dotnet → '8.0', java → '17', powershell → '7.4'."
}

# ---------------------------------------------------------------------------
# App Settings
# ---------------------------------------------------------------------------

variable "app_settings" {
  type        = map(string)
  description = "Additional app settings merged with the auto-generated FUNCTIONS_EXTENSION_VERSION and App Insights settings. Do not set FUNCTIONS_EXTENSION_VERSION or APPLICATIONINSIGHTS_CONNECTION_STRING here — they are managed by the module."
  default     = {}
}

variable "functions_extension_version" {
  type        = string
  description = "Azure Functions runtime version (e.g. ~4 for v4, ~3 for v3). Callers should not normally override this."
  default     = "~4"
}

variable "app_insights_connection_string" {
  type        = string
  description = "Application Insights connection string. Pass the output from the monitoring module. Set to null to skip App Insights wiring."
  sensitive   = true
  default     = null
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to all resources."
  default     = {}
}
