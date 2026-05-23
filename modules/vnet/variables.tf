variable "location" {
  type        = string
  description = "Azure region for all networking resources."
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group to deploy the VNet into."
}

variable "vnet_name" {
  type        = string
  description = "Name for the virtual network (e.g. 'vnet-myapp-dev')."
}

variable "vnet_address_prefix" {
  type        = string
  description = "Address prefix for the VNet in CIDR notation. Must be at least /16 (e.g. '10.1.0.0/16'). Subnets are computed automatically via cidrsubnet()."

  validation {
    condition     = can(cidrhost(var.vnet_address_prefix, 0))
    error_message = "vnet_address_prefix must be a valid CIDR block (e.g. '10.1.0.0/16')."
  }
}

variable "app_subnet_delegation" {
  type        = string
  description = "Service delegation for the app subnet. Use 'Microsoft.Web/serverFarms' for App Service, 'Microsoft.App/environments' for Container Apps."
  default     = "Microsoft.Web/serverFarms"
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to all networking resources."
  default     = {}
}

variable "enable_ddos_protection" {
  type        = bool
  description = "Attach an Azure DDoS Network Protection plan to this VNet. Requires ddos_protection_plan_id."
  default     = false
}

variable "ddos_protection_plan_id" {
  type        = string
  description = "Resource ID of an existing azurerm_network_ddos_protection_plan. Required when enable_ddos_protection = true."
  default     = null
}
