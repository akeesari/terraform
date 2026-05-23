variable "name" {
  type        = string
  description = "Front Door profile name (2–64 chars, globally unique, alphanumeric and hyphens)."

  validation {
    condition     = can(regex("^[a-zA-Z0-9][a-zA-Z0-9-]{0,62}[a-zA-Z0-9]$", var.name))
    error_message = "name must be 2–64 chars, start/end with alphanumeric, and contain only alphanumeric and hyphens."
  }
}

variable "resource_group_name" {
  type        = string
  description = "Resource group to place the Front Door profile in."
}

variable "location" {
  type        = string
  description = "Azure region. Front Door is a global service; this controls where resource metadata is stored."
}

variable "sku_name" {
  type        = string
  description = "Front Door SKU. Standard_AzureFrontDoor or Premium_AzureFrontDoor. WAF managed rule sets require Premium."
  default     = "Standard_AzureFrontDoor"

  validation {
    condition     = contains(["Standard_AzureFrontDoor", "Premium_AzureFrontDoor"], var.sku_name)
    error_message = "sku_name must be Standard_AzureFrontDoor or Premium_AzureFrontDoor."
  }
}

variable "response_timeout_seconds" {
  type        = number
  description = "Maximum time Front Door waits for a response from the origin (16–240 seconds)."
  default     = 120

  validation {
    condition     = var.response_timeout_seconds >= 16 && var.response_timeout_seconds <= 240
    error_message = "response_timeout_seconds must be between 16 and 240."
  }
}

variable "session_affinity_enabled" {
  type        = bool
  description = "Enable session affinity so repeat requests from the same client go to the same origin."
  default     = false
}

variable "restore_traffic_time_to_healed_in_minutes" {
  type        = number
  description = "Minutes to gradually ramp up traffic to a recovered origin (0 = instant restore, max 50)."
  default     = 10

  validation {
    condition     = var.restore_traffic_time_to_healed_in_minutes >= 0 && var.restore_traffic_time_to_healed_in_minutes <= 50
    error_message = "restore_traffic_time_to_healed_in_minutes must be between 0 and 50."
  }
}

variable "additional_latency_in_milliseconds" {
  type        = number
  description = "Extra latency tolerance when selecting an origin during load balancing (0 = always pick lowest latency)."
  default     = 50
}

variable "health_probe_interval_in_seconds" {
  type        = number
  description = "Interval between health probes sent to each origin (5–255 seconds)."
  default     = 30

  validation {
    condition     = var.health_probe_interval_in_seconds >= 5 && var.health_probe_interval_in_seconds <= 255
    error_message = "health_probe_interval_in_seconds must be between 5 and 255."
  }
}

variable "health_probe_path" {
  type        = string
  description = "HTTP path used for origin health probes."
  default     = "/health"
}

variable "origins" {
  type = map(object({
    host_name   = string
    host_header = optional(string)
    http_port   = optional(number)
    https_port  = optional(number)
    priority    = optional(number)
    weight      = optional(number)
  }))
  description = "Map of origins to register in the origin group. Key = origin resource name. host_header defaults to host_name when omitted."
  default     = {}
}

variable "patterns_to_match" {
  type        = list(string)
  description = "URL path patterns this route matches against incoming requests."
  default     = ["/*"]
}

variable "enable_waf" {
  type        = bool
  description = "Attach a WAF policy to the default endpoint. Premium SKU also enables Microsoft-managed rule sets (DefaultRuleSet + BotManager)."
  default     = false
}

variable "waf_mode" {
  type        = string
  description = "WAF firewall mode: Detection (log only) or Prevention (block threats). Use Detection for dev/test, Prevention for production."
  default     = "Prevention"

  validation {
    condition     = contains(["Detection", "Prevention"], var.waf_mode)
    error_message = "waf_mode must be either Detection or Prevention."
  }
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to all Front Door resources."
  default     = {}
}
