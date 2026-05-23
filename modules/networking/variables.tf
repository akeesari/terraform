variable "resource_group_name" {
  type        = string
  description = "Resource group where networking resources will be created."
}

variable "location" {
  type        = string
  description = "Azure region for all networking resources."
}

variable "env" {
  type        = string
  description = "Short environment name (e.g. dev, prod). Used for naming conventions."
  default     = null
}

variable "vnet_name" {
  type        = string
  description = "Name of the Virtual Network."
}

variable "address_space" {
  type        = list(string)
  description = "Address space for the Virtual Network in CIDR notation. Must contain at least one CIDR block."

  validation {
    condition     = length(var.address_space) > 0
    error_message = "address_space must not be empty — provide at least one CIDR block."
  }
}

variable "dns_servers" {
  type        = list(string)
  description = "Custom DNS server IP addresses. Empty list uses Azure-provided DNS."
  default     = []
}

variable "subnets" {
  description = "List of subnets to create in the VNet."
  type = list(object({
    name                              = string
    address_prefixes                  = list(string)
    nsg_name                          = optional(string)
    service_endpoints                 = optional(list(string))
    bgp_route_propagation_enabled     = optional(bool, null)
    private_endpoint_network_policies = optional(string, "Enabled")
    route_table = optional(object({
      name = string
      routes = optional(list(object({
        name                   = string
        address_prefix         = string
        next_hop_type          = string
        next_hop_in_ip_address = optional(string, null)
      })), [])
      tags = optional(map(string), {})
    }))
    delegation = optional(list(object({
      name = string
      service_delegation = object({
        name    = string
        actions = list(string)
      })
    })))
    nsg_security_rule = optional(list(object({
      name                       = string
      priority                   = number
      direction                  = string
      access                     = string
      protocol                   = string
      source_port_range          = string
      destination_port_range     = optional(string, null)
      destination_port_ranges    = optional(list(string), [])
      source_address_prefix      = string
      destination_address_prefix = string
    })), [])
  }))
  default = []
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to all networking resources."
  default     = {}
}
