variable "name" {
  type        = string
  description = "Managed Grafana workspace name (2–23 chars, alphanumeric and hyphens, must start and end with alphanumeric)."

  validation {
    condition     = can(regex("^[a-zA-Z0-9][a-zA-Z0-9-]{0,21}[a-zA-Z0-9]$", var.name))
    error_message = "name must be 2–23 chars, start/end with alphanumeric, and contain only alphanumeric and hyphens."
  }
}

variable "resource_group_name" {
  type        = string
  description = "Resource group to place the Managed Grafana workspace in."
}

variable "location" {
  type        = string
  description = "Azure region."
}

variable "sku" {
  type        = string
  description = "Managed Grafana SKU: Standard (full features + SLA) or Essential (limited features, no SLA)."
  default     = "Standard"

  validation {
    condition     = contains(["Standard", "Essential"], var.sku)
    error_message = "sku must be Standard or Essential."
  }
}

variable "grafana_major_version" {
  type        = number
  description = "Grafana major version to deploy (9 or 10)."
  default     = 10

  validation {
    condition     = contains([9, 10], var.grafana_major_version)
    error_message = "grafana_major_version must be 9 or 10."
  }
}

variable "zone_redundancy_enabled" {
  type        = bool
  description = "Enable availability zone redundancy. Requires Standard SKU."
  default     = false
}

variable "api_key_enabled" {
  type        = bool
  description = "Allow API key authentication. Prefer managed identity over API keys where possible."
  default     = false
}

variable "deterministic_outbound_ip_enabled" {
  type        = bool
  description = "Assign deterministic outbound public IPs. Useful for allow-listing Grafana in data source firewalls."
  default     = false
}

variable "public_network_access_enabled" {
  type        = bool
  description = "Allow access from the public internet. Set to false when using private endpoints. Default is false; set true only if no private endpoint is configured."
  default     = false
}

variable "monitoring_scope" {
  type        = string
  description = "Resource ID (subscription or resource group) to grant the Grafana managed identity the Monitoring Reader role. Null = no role assignment."
  default     = null
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to all Managed Grafana resources."
  default     = {}
}
