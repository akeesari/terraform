variable "name" {
  type        = string
  description = "Azure OpenAI account name (e.g. 'oai-myapp-dev')."

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9-]{1,62}[a-zA-Z0-9]$", var.name))
    error_message = "OpenAI account name must be 3–64 chars, start with a letter, and contain only alphanumeric characters and hyphens."
  }
}

variable "resource_group_name" {
  type        = string
  description = "Resource group to deploy the Azure OpenAI account into."
}

variable "location" {
  type        = string
  description = "Azure region. Must be one that supports Azure OpenAI (e.g. 'North Central US')."
}

variable "sku_name" {
  type        = string
  description = "Azure Cognitive Services SKU. Must be 'S0' — the only valid SKU for OpenAI kind."
  default     = "S0"

  validation {
    condition     = var.sku_name == "S0"
    error_message = "sku_name must be 'S0' — the only valid SKU for Azure OpenAI."
  }
}

variable "custom_subdomain_name" {
  type        = string
  description = "Globally unique custom subdomain for the OpenAI REST endpoint (e.g. 'oai-myapp-dev'). Required for Azure AD / managed-identity authentication."
}

variable "public_network_access_enabled" {
  type        = bool
  description = "Allow inbound public internet traffic. Set false in prod (requires Private Endpoint); true in dev for local testing."
  default     = false
}

variable "local_auth_enabled" {
  type        = bool
  description = "Enable key-based authentication. Must be false in production to enforce managed-identity-only access. Only set true in dev for local testing."
  default     = false
}

variable "deployments" {
  type = map(object({
    model_name    = string
    model_version = string
    sku_name      = string
    capacity      = number
  }))
  description = "Map of model deployments keyed by deployment name. sku_name: GlobalStandard, Standard, or DataZoneStandard. capacity = TPM quota in thousands (e.g. 30 = 30 K TPM)."
  default     = {}
}

variable "enable_management_lock" {
  type        = bool
  description = "Create a CanNotDelete management lock on the OpenAI account. Set true in prod."
  default     = false
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to all resources in this module."
  default     = {}
}
