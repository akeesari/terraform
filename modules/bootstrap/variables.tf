variable "subscription_id" {
  description = "Azure subscription ID where bootstrap resources will be created; used for the SP Contributor role assignment scope"
  type        = string
}

variable "admin_user_object_id" {
  description = "Object ID of the admin/owner user granted Get/List/Set access to Key Vault (find in Azure Portal → Users → user → Object ID)"
  type        = string

  validation {
    condition     = can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.admin_user_object_id))
    error_message = "admin_user_object_id must be a valid UUID (e.g. 61d658d7-7792-4a77-b7c6-9084bd5dadff)."
  }
}

variable "service_principal_name" {
  description = "Display name of the Terraform automation Service Principal created for this project"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group that contains all bootstrap infrastructure (state storage + Key Vault)"
  type        = string
}

variable "location" {
  description = "Azure region for all bootstrap resources"
  type        = string
}

variable "storage_account_name" {
  description = "Name of the storage account that holds Terraform remote state files (3–24 chars, lowercase alphanumeric, globally unique)"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]{3,24}$", var.storage_account_name))
    error_message = "storage_account_name must be 3–24 lowercase alphanumeric characters with no hyphens or spaces."
  }
}

variable "storage_account_sku" {
  description = "Replication SKU for the Terraform state storage account"
  type        = string
  default     = "Standard_LRS"

  validation {
    condition     = contains(["Standard_LRS", "Standard_GRS", "Standard_RAGRS", "Standard_ZRS"], var.storage_account_sku)
    error_message = "storage_account_sku must be one of: Standard_LRS, Standard_GRS, Standard_RAGRS, Standard_ZRS."
  }
}

variable "storage_container_name" {
  description = "Name of the blob container inside the storage account for Terraform state files"
  type        = string
  default     = "tfstate"
}

variable "key_vault_name" {
  description = "Name of the Key Vault used to store Terraform credentials as secrets (3–24 chars)"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9-]{1,22}[a-zA-Z0-9]$", var.key_vault_name))
    error_message = "key_vault_name must be 3–24 characters, start with a letter, and contain only letters, digits, or hyphens."
  }
}

variable "tags" {
  description = "Tags applied to every resource created by this module"
  type        = map(string)
  default     = {}
}
