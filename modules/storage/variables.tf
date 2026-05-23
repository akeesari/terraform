variable "name" {
  type        = string
  description = "Storage account name (3–24 lowercase alphanumeric, globally unique)."
  default     = ""

  validation {
    condition     = !var.enable_storage || can(regex("^[a-z0-9]{3,24}$", var.name))
    error_message = "Storage account name must be 3–24 lowercase alphanumeric characters with no hyphens."
  }
}

variable "resource_group_name" {
  type        = string
  description = "Resource group to place the storage account in."
}

variable "location" {
  type        = string
  description = "Azure region."
}

variable "replication_type" {
  type        = string
  description = "Replication type: LRS, ZRS, GRS, RAGRS, GZRS, RAGZRS."
  default     = "LRS"

  validation {
    condition     = contains(["LRS", "ZRS", "GRS", "RAGRS", "GZRS", "RAGZRS"], var.replication_type)
    error_message = "replication_type must be one of: LRS, ZRS, GRS, RAGRS, GZRS, RAGZRS."
  }
}

variable "account_tier" {
  type        = string
  description = "Storage account performance tier: Standard or Premium."
  default     = "Standard"

  validation {
    condition     = contains(["Standard", "Premium"], var.account_tier)
    error_message = "account_tier must be Standard or Premium."
  }
}

variable "enable_hierarchical_namespace" {
  type        = bool
  description = "Enable hierarchical namespace (Azure Data Lake Storage Gen2). Cannot be changed after account creation."
  default     = false
}

variable "tier_to_cool_after_days" {
  type        = number
  description = "Days since last modification before blobs are tiered to Cool. Default: 30."
  default     = 30
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to all storage resources."
  default     = {}
}

variable "enable_storage" {
  type        = bool
  description = "Set to false to skip creating the storage account and all related resources."
  default     = true
}

variable "containers" {
  type        = list(string)
  description = "Names of private blob containers to create inside the storage account."
  default     = []
}

variable "queues" {
  type        = list(string)
  description = "Names of storage queues to create inside the storage account."
  default     = []
}
