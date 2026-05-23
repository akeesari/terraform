variable "enable_dns_zone" {
  type        = bool
  description = "Toggle creation of the DNS zone."
  default     = true
}

variable "zone_name" {
  type        = string
  description = "Fully qualified DNS zone name (e.g. dev.example.com)."
}

variable "zone_type" {
  type        = string
  description = "Type of DNS zone to create. Must be 'public' or 'private'."
  default     = "public"

  validation {
    condition     = contains(["public", "private"], var.zone_type)
    error_message = "zone_type must be 'public' or 'private'."
  }
}

variable "resource_group_name" {
  type        = string
  description = "Resource group where the DNS zone will be created."
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to all resources in this module."
  default     = {}
}

# ---------------------------------------------------------------------------
# Parent Zone Delegation (public zones only)
# ---------------------------------------------------------------------------

variable "enable_parent_delegation" {
  type        = bool
  description = "When true, create NS records in the parent zone to delegate this subdomain. Applies to public zones only."
  default     = false
}

variable "subdomain_prefix" {
  type        = string
  description = "Subdomain label used as the NS record name in the parent zone (e.g. 'dev' for dev.example.com)."
  default     = ""
}

variable "parent_zone_name" {
  type        = string
  description = "Parent DNS zone FQDN (e.g. example.com). Required when enable_parent_delegation = true."
  default     = ""
}

variable "parent_zone_resource_group" {
  type        = string
  description = "Resource group containing the parent DNS zone. Required when enable_parent_delegation = true."
  default     = ""
}

variable "delegation_ttl" {
  type        = number
  description = "TTL in seconds for the NS delegation record in the parent zone."
  default     = 3600
}

# ---------------------------------------------------------------------------
# Private DNS Zone — Virtual Network Links
# ---------------------------------------------------------------------------

variable "virtual_network_links" {
  description = "List of virtual network links to attach to the private DNS zone. Ignored for public zones."
  type = list(object({
    name                 = string
    virtual_network_id   = string
    registration_enabled = optional(bool, false)
  }))
  default = []
}

# ---------------------------------------------------------------------------
# Private DNS Zone — SOA Record Override
# ---------------------------------------------------------------------------

variable "soa_record" {
  description = "Optional SOA record override for the private DNS zone. Ignored for public zones."
  type = object({
    email        = optional(string, "azureprivatedns-host.microsoft.com")
    expire_time  = optional(number, 2419200)
    minimum_ttl  = optional(number, 10)
    refresh_time = optional(number, 3600)
    retry_time   = optional(number, 300)
    ttl          = optional(number, 3600)
  })
  default = null
}


