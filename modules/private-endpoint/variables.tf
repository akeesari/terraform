variable "name" {
  type        = string
  description = "Private endpoint resource name (e.g. 'pep-redis-myapp-dev')."

  validation {
    condition     = length(var.name) >= 2 && length(var.name) <= 80
    error_message = "name must be between 2 and 80 characters."
  }
}

variable "resource_group_name" {
  type        = string
  description = "Resource group in which to create the private endpoint and DNS resources."
}

variable "location" {
  type        = string
  description = "Azure region for the private endpoint."
}

variable "subnet_id" {
  type        = string
  description = "Resource ID of the subnet in which to place the private endpoint NIC (snet-data)."
}

variable "target_resource_id" {
  type        = string
  description = "Resource ID of the target Azure service (Redis, Storage, Key Vault, OpenAI, etc.)."
}

variable "subresource_names" {
  type        = list(string)
  description = "Subresource name(s) for the private connection. Examples: ['redisCache'], ['blob'], ['vault'], ['account']."

  validation {
    condition     = length(var.subresource_names) > 0
    error_message = "subresource_names must have at least one entry."
  }
}

variable "private_dns_zone_name" {
  type        = string
  description = "Private DNS zone name for the service. Examples: 'privatelink.redis.cache.windows.net', 'privatelink.blob.core.windows.net', 'privatelink.vaultcore.azure.net', 'privatelink.openai.azure.com'."
}

variable "vnet_id" {
  type        = string
  description = "Resource ID of the VNet to link to the private DNS zone."
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to all resources in this module."
  default     = {}
}
