variable "enable_management_groups" {
  description = "Set to true to provision the management group hierarchy."
  type        = bool
  default     = false
}

variable "company_name" {
  description = "Company name used in management group naming (e.g. 'contoso')."
  type        = string
}

variable "display_name" {
  description = "Management group display name. Defaults to '<company_name> Landing Zone'."
  type        = string
  default     = ""
}

variable "parent_management_group_id" {
  description = "Resource ID of the parent management group. Null places the group under the tenant root."
  type        = string
  default     = null
}

variable "prod_subscription_id" {
  description = "Production subscription ID to place under this management group. Leave empty for parent MGs with no direct subscriptions."
  type        = string
  default     = ""
  validation {
    condition     = var.prod_subscription_id == "" || can(regex("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", var.prod_subscription_id))
    error_message = "prod_subscription_id must be a valid UUID or empty string."
  }
}

variable "nonprod_subscription_id" {
  description = "Non-production subscription ID to place under this management group. Leave empty for parent MGs with no direct subscriptions."
  type        = string
  default     = ""
  validation {
    condition     = var.nonprod_subscription_id == "" || can(regex("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", var.nonprod_subscription_id))
    error_message = "nonprod_subscription_id must be a valid UUID or empty string."
  }
}

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
  default     = {}
}
