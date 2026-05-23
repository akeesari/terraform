variable "name" {
  type        = string
  description = "Azure Container Registry name (5–50 chars, alphanumeric only, globally unique)."

  validation {
    condition     = can(regex("^[a-zA-Z0-9]{5,50}$", var.name))
    error_message = "ACR name must be 5–50 alphanumeric characters with no hyphens or special chars."
  }
}
variable "resource_group_name" {
  type        = string
  description = "Target Azure resource group name."
}
variable "location" {
  type        = string
  description = "Azure region for the ACR."
}
variable "sku" {
  type        = string
  description = "ACR SKU: Basic, Standard, or Premium. Geo-replication and network rule sets require Premium."
  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.sku)
    error_message = "sku must be Basic, Standard, or Premium."
  }
}
variable "admin_enabled" {
  type        = bool
  description = "Enable the admin user (avoid in production; prefer service principals)."
  default     = false
}

variable "enable_acr" {
  type        = bool
  description = "Toggle creation of Azure Container Registry."
  default     = true
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to the ACR resource."
  default     = {}
}

# ---------------------------------------------------------------------------
# Geo-replication (Premium SKU only)
# ---------------------------------------------------------------------------

variable "geo_replication_locations" {
  type        = list(string)
  description = "Azure regions to create geo-replicas in. Only applied when sku = 'Premium'. Example: [\"eastus\", \"westeurope\"]."
  default     = []
}

# ---------------------------------------------------------------------------
# Network rule set (Premium SKU only)
# ---------------------------------------------------------------------------

variable "enable_network_rule_set" {
  type        = bool
  description = "When true (and sku = 'Premium'), apply a Deny-all network rule set. Use ip_rules and allowed_subnet_ids to permit specific sources."
  default     = false
}

variable "ip_rules" {
  type        = list(string)
  description = "CIDR ranges allowed to reach the registry when enable_network_rule_set = true."
  default     = []
}

variable "allowed_subnet_ids" {
  type        = list(string)
  description = "Subnet resource IDs allowed to reach the registry when enable_network_rule_set = true."
  default     = []
}
