variable "name" {
  type        = string
  description = "Event Hub namespace name (globally unique, 6–50 characters, letters/numbers/hyphens)."

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9-]{4,48}[a-zA-Z0-9]$", var.name))
    error_message = "Event Hub namespace name must be 6–50 characters, start with a letter, and contain only letters, numbers, and hyphens."
  }
}

variable "resource_group_name" {
  type        = string
  description = "Resource group to place the Event Hub namespace in."
}

variable "location" {
  type        = string
  description = "Azure region."
}

variable "sku" {
  type        = string
  description = "Event Hub namespace SKU. Basic supports only one consumer group per hub; Standard and Premium support multiple groups and Kafka."
  default     = "Standard"

  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.sku)
    error_message = "sku must be Basic, Standard, or Premium."
  }
}

variable "capacity" {
  type        = number
  description = "Throughput units (Standard) or processing units (Premium). Range: 1–40."
  default     = 1

  validation {
    condition     = var.capacity >= 1 && var.capacity <= 40
    error_message = "capacity must be between 1 and 40."
  }
}

# ---------------------------------------------------------------------------
# Auto-inflate (Standard SKU only)
# ---------------------------------------------------------------------------

variable "auto_inflate_enabled" {
  type        = bool
  description = "Automatically scale up throughput units when ingestion throughput is exceeded (Standard SKU only)."
  default     = false
}

variable "maximum_throughput_units" {
  type        = number
  description = "Upper bound for auto-inflate (1–40, Standard SKU only). Only used when auto_inflate_enabled = true."
  default     = 20

  validation {
    condition     = var.maximum_throughput_units >= 1 && var.maximum_throughput_units <= 40
    error_message = "maximum_throughput_units must be between 1 and 40."
  }
}

variable "public_network_access_enabled" {
  type        = bool
  description = "Allow public network access. Defaults to false; set to true only in dev when no private endpoint is used."
  default     = false
}

# ---------------------------------------------------------------------------
# Event Hubs
# ---------------------------------------------------------------------------

variable "hubs" {
  type = list(object({
    name              = string
    partition_count   = optional(number, 4)
    message_retention = optional(number, 1)
  }))
  description = "Event Hubs to create inside the namespace. partition_count is immutable after creation — choose carefully. message_retention is in days (1 for Basic; 1–90 for Standard/Premium)."
  default     = []
}

# ---------------------------------------------------------------------------
# Consumer Groups
# ---------------------------------------------------------------------------

variable "consumer_groups" {
  type = list(object({
    eventhub_name = string
    name          = string
    user_metadata = optional(string, null)
  }))
  description = "Additional consumer groups to create. The built-in '$Default' group always exists and must not be declared here."
  default     = []
}

# ---------------------------------------------------------------------------
# Management Lock
# ---------------------------------------------------------------------------

variable "enable_management_lock" {
  type        = bool
  description = "Create a CanNotDelete management lock on the namespace to guard against accidental deletion."
  default     = false
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to all resources."
  default     = {}
}
