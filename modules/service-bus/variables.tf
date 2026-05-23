variable "name" {
  type        = string
  description = "Service Bus namespace name (globally unique, 6–50 characters, letters/numbers/hyphens)."

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9-]{4,48}[a-zA-Z0-9]$", var.name))
    error_message = "Service Bus namespace name must be 6–50 characters, start with a letter, and contain only letters, numbers, and hyphens."
  }
}

variable "resource_group_name" {
  type        = string
  description = "Resource group to place the Service Bus namespace in."
}

variable "location" {
  type        = string
  description = "Azure region."
}

variable "sku" {
  type        = string
  description = "Service Bus namespace SKU. Topics require Standard or Premium."
  default     = "Standard"

  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.sku)
    error_message = "sku must be Basic, Standard, or Premium."
  }
}

variable "capacity" {
  type        = number
  description = "Messaging units for Premium SKU (1, 2, 4, 8, or 16). Ignored for Basic and Standard."
  default     = 1

  validation {
    condition     = contains([1, 2, 4, 8, 16], var.capacity)
    error_message = "capacity must be 1, 2, 4, 8, or 16."
  }
}

variable "public_network_access_enabled" {
  type        = bool
  description = "Allow public network access. Defaults to false; set to true only in dev when no private endpoint is used."
  default     = false
}

# ---------------------------------------------------------------------------
# Queues
# ---------------------------------------------------------------------------

variable "queues" {
  type = list(object({
    name                                 = string
    max_delivery_count                   = optional(number, 10)
    lock_duration                        = optional(string, "PT1M")
    dead_lettering_on_message_expiration = optional(bool, true)
    default_message_ttl                  = optional(string, null)
  }))
  description = "Queues to create inside the namespace. dead_lettering_on_message_expiration defaults to true — undeliverable messages are moved to the dead-letter sub-queue rather than silently dropped."
  default     = []
}

# ---------------------------------------------------------------------------
# Topics
# ---------------------------------------------------------------------------

variable "topics" {
  type        = list(string)
  description = "Topic names to create. Requires Standard or Premium SKU. Subscriptions to topics must be managed at the stack level."
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
