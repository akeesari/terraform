variable "enable_nat_gateway" {
  type        = bool
  description = "Toggle creation of the NAT Gateway and its associated public IP prefix and subnet associations."
  default     = true
}

variable "name" {
  type        = string
  description = "NAT Gateway name (1–80 chars, alphanumeric, hyphens, underscores, and periods)."

  validation {
    condition     = can(regex("^[a-zA-Z0-9][a-zA-Z0-9._-]{0,78}[a-zA-Z0-9_]$", var.name))
    error_message = "name must be 1–80 chars, start with alphanumeric, and contain only alphanumeric, hyphens, underscores, and periods."
  }
}

variable "resource_group_name" {
  type        = string
  description = "Resource group to place the NAT Gateway in."
}

variable "location" {
  type        = string
  description = "Azure region."
}

variable "prefix_length" {
  type        = number
  description = "Public IP prefix length (/28–/31). /28 = 16 IPs, /29 = 8, /30 = 4, /31 = 2."
  default     = 31

  validation {
    condition     = var.prefix_length >= 28 && var.prefix_length <= 31
    error_message = "prefix_length must be between 28 and 31."
  }
}

variable "idle_timeout_in_minutes" {
  type        = number
  description = "TCP idle connection timeout in minutes (4–120)."
  default     = 10

  validation {
    condition     = var.idle_timeout_in_minutes >= 4 && var.idle_timeout_in_minutes <= 120
    error_message = "idle_timeout_in_minutes must be between 4 and 120."
  }
}

variable "zones" {
  type        = list(string)
  description = "Availability zones to pin the NAT Gateway to (e.g. [\"1\"]). Empty list = no zone constraint."
  default     = []
}

variable "subnet_ids" {
  type        = list(string)
  description = "List of subnet resource IDs to associate with the NAT Gateway. Outbound traffic from these subnets will use the attached IP prefix."
  default     = []
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to all NAT Gateway resources."
  default     = {}
}
