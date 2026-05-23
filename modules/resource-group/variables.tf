variable "name" {
  type        = string
  description = "Resource Group name (alphanumeric, periods, underscores, parentheses, hyphens; max 90 chars)."
  validation {
    condition     = can(regex("^[a-zA-Z0-9._()-]{1,90}$", var.name))
    error_message = "Resource group name must match ^[a-zA-Z0-9._()-]{1,90}$."
  }
}

variable "location" {
  type        = string
  description = "Azure region (e.g. eastus, westus2)."
}

variable "tags" {
  type        = map(string)
  description = "Baseline tags applied to the resource group (e.g. environment, team)."
  default     = {}
}

variable "extra_tags" {
  type        = map(string)
  description = "Additional tags merged with baseline tags."
  default     = {}
}

variable "enable_management_lock" {
  type        = bool
  description = "When true, create a CanNotDelete management lock on the resource group."
  default     = false
}
