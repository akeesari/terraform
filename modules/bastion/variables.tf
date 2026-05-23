variable "name" {
  type        = string
  description = "Bastion host name (1–80 chars, alphanumeric, hyphens, underscores, and periods)."

  validation {
    condition     = can(regex("^[a-zA-Z0-9][a-zA-Z0-9._-]{0,78}[a-zA-Z0-9_]$", var.name))
    error_message = "name must be 1–80 chars, start with alphanumeric, and contain only alphanumeric, hyphens, underscores, and periods."
  }
}

variable "resource_group_name" {
  type        = string
  description = "Resource group to place the Bastion host in."
}

variable "location" {
  type        = string
  description = "Azure region."
}

variable "subnet_id" {
  type        = string
  description = "Resource ID of the 'AzureBastionSubnet' subnet. Azure requires this exact subnet name."
}

variable "sku" {
  type        = string
  description = "Bastion SKU: Basic (RDP/SSH only) or Standard (tunneling, file copy, IP connect, shareable links)."
  default     = "Standard"

  validation {
    condition     = contains(["Basic", "Standard"], var.sku)
    error_message = "sku must be Basic or Standard."
  }
}

variable "scale_units" {
  type        = number
  description = "Number of scale units (2–50). Each unit adds connection capacity. Minimum 2 for Standard SKU."
  default     = 2

  validation {
    condition     = var.scale_units >= 2 && var.scale_units <= 50
    error_message = "scale_units must be between 2 and 50."
  }
}

variable "file_copy_enabled" {
  type        = bool
  description = "Enable file copy over RDP sessions. Standard SKU only."
  default     = false
}

variable "tunneling_enabled" {
  type        = bool
  description = "Enable native client (SSH/RDP) tunneling. Standard SKU only."
  default     = false
}

variable "ip_connect_enabled" {
  type        = bool
  description = "Enable connecting to VMs by IP address instead of resource ID. Standard SKU only."
  default     = false
}

variable "shareable_link_enabled" {
  type        = bool
  description = "Enable shareable links for VM connections. Standard SKU only."
  default     = false
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to all Bastion resources."
  default     = {}
}
