variable "name" {
  type        = string
  description = "Application Insights resource name."

  validation {
    condition     = length(var.name) >= 1 && length(var.name) <= 260
    error_message = "Application Insights name must be 1–260 characters."
  }
}

variable "resource_group_name" {
  type        = string
  description = "Resource group to place the Application Insights instance in."
}

variable "location" {
  type        = string
  description = "Azure region."
}

variable "application_type" {
  type        = string
  description = "Type of application being monitored. Common values: web, ios, java, MobileCenter, Node.JS, other, phone, store."
  default     = "web"

  validation {
    condition     = contains(["web", "ios", "java", "MobileCenter", "Node.JS", "other", "phone", "store"], var.application_type)
    error_message = "application_type must be one of: web, ios, java, MobileCenter, Node.JS, other, phone, store."
  }
}

variable "workspace_id" {
  type        = string
  description = "Log Analytics Workspace resource ID to link this Application Insights instance. Required for workspace-based (modern) mode."
  default     = null
}

variable "retention_in_days" {
  type        = number
  description = "Data retention period in days. Must be 30, 60, 90, 120, 180, 270, 365, 550, or 730."
  default     = 90

  validation {
    condition     = contains([30, 60, 90, 120, 180, 270, 365, 550, 730], var.retention_in_days)
    error_message = "retention_in_days must be one of: 30, 60, 90, 120, 180, 270, 365, 550, 730."
  }
}

variable "enable_application_insights" {
  type        = bool
  description = "Set to false to skip creating the Application Insights instance."
  default     = true
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to the Application Insights resource."
  default     = {}
}
