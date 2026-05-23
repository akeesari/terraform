variable "name" {
  type        = string
  description = "Redis Cache name (1–63 chars, globally unique, lowercase alphanumeric and hyphens)."
  default     = ""

  validation {
    condition     = !var.enable_redis || can(regex("^[a-z0-9][a-z0-9-]{0,61}[a-z0-9]$", var.name))
    error_message = "Redis name must be 1–63 chars, start/end with alphanumeric, and contain only lowercase alphanumeric and hyphens."
  }
}

variable "resource_group_name" {
  type        = string
  description = "Resource group to place the Redis cache in."
}

variable "location" {
  type        = string
  description = "Azure region."
}

variable "sku_name" {
  type        = string
  description = "Redis SKU: Basic, Standard, or Premium. Standard provides replication; Premium adds clustering and persistence."
  default     = "Standard"

  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.sku_name)
    error_message = "sku_name must be Basic, Standard, or Premium."
  }
}

variable "family" {
  type        = string
  description = "SKU family: C (Basic/Standard) or P (Premium)."
  default     = "C"

  validation {
    condition     = contains(["C", "P"], var.family)
    error_message = "family must be C or P."
  }
}

variable "capacity" {
  type        = number
  description = "SKU capacity. For C family: 0=250MB, 1=1GB, 2=2.5GB, 3=6GB, 4=13GB, 5=26GB, 6=53GB."
  default     = 0
}

variable "maxmemory_policy" {
  type        = string
  description = "Redis eviction policy when memory is full."
  default     = "allkeys-lru"

  validation {
    condition = contains([
      "noeviction", "allkeys-lru", "volatile-lru",
      "allkeys-random", "volatile-random", "volatile-ttl",
      "allkeys-lfu", "volatile-lfu"
    ], var.maxmemory_policy)
    error_message = "maxmemory_policy must be a valid Redis eviction policy."
  }
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to all Redis resources."
  default     = {}
}

variable "enable_redis" {
  type        = bool
  description = "Set to false to skip creating the Redis cache."
  default     = true
}
