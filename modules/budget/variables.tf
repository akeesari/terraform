variable "name" {
  type        = string
  description = "Budget resource name (e.g. 'budget-myapp-dev'). Must be unique within the resource group scope."
}

variable "resource_group_id" {
  type        = string
  description = "Resource group ID to scope the budget to (e.g. azurerm_resource_group.this.id)."
}

variable "amount" {
  type        = number
  description = "Monthly budget ceiling in USD. Alerts fire at 50%, 80%, and 100% of this value."

  validation {
    condition     = var.amount > 0
    error_message = "Budget amount must be greater than 0."
  }
}

variable "contact_emails" {
  type        = list(string)
  description = "Email addresses to notify when a budget threshold is breached. At least one address required."

  validation {
    condition     = length(var.contact_emails) > 0
    error_message = "At least one contact email must be provided."
  }
}

variable "start_date" {
  type        = string
  description = "Budget start date in RFC3339 format. Must be the first day of a month (e.g. '2026-05-01T00:00:00Z')."

  validation {
    condition     = can(regex("^\\d{4}-\\d{2}-01T00:00:00Z$", var.start_date))
    error_message = "start_date must be the first day of a month in RFC3339 format, e.g. '2026-05-01T00:00:00Z'."
  }
}

variable "tags" {
  type        = map(string)
  description = "Tags map — accepted for stack-level consistency; azurerm_consumption_budget_resource_group does not support tags so this variable is intentionally unused."
  default     = {}
}
