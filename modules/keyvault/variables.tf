variable "name" {
  type        = string
  description = "Key Vault name (3–24 chars, alphanumeric and hyphens, globally unique)."

  validation {
    condition     = length(var.name) >= 3 && length(var.name) <= 24 && can(regex("^[a-zA-Z][a-zA-Z0-9-]*$", var.name))
    error_message = "Key Vault name must be 3–24 characters, start with a letter, and contain only alphanumerics and hyphens."
  }
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group to deploy the Key Vault into."
}

variable "location" {
  type        = string
  description = "Azure region for the Key Vault."
}

variable "sku_name" {
  type        = string
  description = "Key Vault SKU: 'standard' or 'premium'. Use premium only if HSM-backed keys are required."
  default     = "standard"

  validation {
    condition     = contains(["standard", "premium"], var.sku_name)
    error_message = "sku_name must be 'standard' or 'premium'."
  }
}

variable "soft_delete_retention_days" {
  type        = number
  description = "Number of days soft-deleted secrets are retained (7–90). Azure minimum is 7."
  default     = 90

  validation {
    condition     = var.soft_delete_retention_days >= 7 && var.soft_delete_retention_days <= 90
    error_message = "soft_delete_retention_days must be between 7 and 90."
  }
}

variable "purge_protection_enabled" {
  type        = bool
  description = "Enable purge protection — prevents permanent deletion of secrets during retention period. Set true in prod, false in dev (allows clean destroy)."
  default     = true
}

variable "enable_disk_encryption" {
  type        = bool
  description = "Enable this Key Vault for disk encryption operations."
  default     = false
}

variable "enable_management_lock" {
  type        = bool
  description = "Create a CanNotDelete management lock on the Key Vault. Set true in prod."
  default     = false
}

variable "ip_rules" {
  type        = list(string)
  description = "IP address ranges (CIDR) that can bypass the 'Deny all' firewall. In dev, use ['0.0.0.0/0'] so Terraform can run from any machine. In prod, leave empty and rely on Private Endpoints."
  default     = []
}

variable "allow_unrestricted_network_access" {
  type        = bool
  description = "Set true ONLY for intentional dev/test environments where no Private Endpoint and no IP rules are configured. Bypasses the open-vault precondition. Must not be true in production."
  default     = false
}

variable "allowed_subnet_ids" {
  type        = list(string)
  description = "VNet subnet IDs allowed through the network ACL."
  default     = []
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to the Key Vault."
  default     = {}
}

# ---------------------------------------------------------------------------
# Private Endpoint
# ---------------------------------------------------------------------------

variable "enable_private_endpoints" {
  type        = bool
  description = "Restrict public access and enable a private endpoint in the data subnet."
  default     = false
}

variable "private_endpoint_subnet_id" {
  type        = string
  description = "Subnet ID for the Key Vault private endpoint NIC. Required when enable_private_endpoints = true."
  default     = null
}

variable "key_vault_dns_zone_id" {
  type        = string
  description = "Private DNS zone resource ID (privatelink.vaultcore.azure.net) for DNS resolution. Required when enable_private_endpoints = true."
  default     = null
}

# ---------------------------------------------------------------------------
# Customer-Managed Keys (CMK)
# ---------------------------------------------------------------------------

variable "enable_postgres_cmk" {
  type        = bool
  description = "Create an RSA 2048 CMK for PostgreSQL transparent data encryption."
  default     = false
}

variable "enable_storage_cmk" {
  type        = bool
  description = "Create an RSA 2048 CMK for Storage Account encryption."
  default     = false
}

# ---------------------------------------------------------------------------
# RBAC Role Assignments
# ---------------------------------------------------------------------------

variable "grant_terraform_admin" {
  type        = bool
  description = "Grant the Terraform caller Key Vault Administrator role for initial secret/key setup."
  default     = false
}

variable "terraform_principal_id" {
  type        = string
  description = "Principal ID to grant administrator access. Defaults to the current caller when null."
  default     = null
}

variable "user_principal_ids" {
  type        = list(string)
  description = "Object IDs of users or service principals to grant Key Vault Secrets Officer access."
  default     = []
}

variable "postgres_identity_principal_id" {
  type        = string
  description = "PostgreSQL server system-assigned managed identity principal ID for CMK access."
  default     = null
}

variable "storage_identity_principal_id" {
  type        = string
  description = "Storage Account system-assigned managed identity principal ID for CMK access."
  default     = null
}

variable "enable_aks_connection" {
  type        = bool
  description = "Grant the AKS Key Vault Secrets Provider identity read access for the CSI Secrets Store driver."
  default     = false
}

variable "aks_secrets_provider_identity_id" {
  type        = string
  description = "Object ID of the AKS Key Vault Secrets Provider managed identity. Required when enable_aks_connection = true."
  default     = null
}

# ---------------------------------------------------------------------------
# Diagnostic Settings
# ---------------------------------------------------------------------------

variable "enable_diagnostic_settings" {
  type        = bool
  description = "Send Key Vault audit logs and metrics to a Log Analytics Workspace."
  default     = false
}

variable "log_analytics_workspace_id" {
  type        = string
  description = "Log Analytics Workspace resource ID for diagnostic settings. Required when enable_diagnostic_settings = true."
  default     = null
}
