variable "name" {
  type        = string
  description = "Container Apps Environment name (2–32 characters, letters, numbers, and hyphens)."

  validation {
    condition     = can(regex("^[a-zA-Z0-9][a-zA-Z0-9-]{0,30}[a-zA-Z0-9]$", var.name))
    error_message = "Container Apps Environment name must be 2–32 characters and contain only letters, numbers, and hyphens."
  }
}

variable "resource_group_name" {
  type        = string
  description = "Resource group to place the Container Apps Environment in."
}

variable "location" {
  type        = string
  description = "Azure region."
}

variable "log_analytics_workspace_id" {
  type        = string
  description = "Log Analytics Workspace resource ID for environment diagnostics. Recommended for production."
  default     = null
}

# ---------------------------------------------------------------------------
# VNet integration
# ---------------------------------------------------------------------------

variable "infrastructure_subnet_id" {
  type        = string
  description = "Subnet resource ID for VNet integration. The subnet must be delegated to Microsoft.App/environments and sized /23 or larger. When null, the environment is deployed with a public IP."
  default     = null
}

variable "internal_load_balancer_enabled" {
  type        = bool
  description = "Use an internal (private) load balancer for the environment. Only applies when infrastructure_subnet_id is set."
  default     = false
}

variable "zone_redundancy_enabled" {
  type        = bool
  description = "Enable zone redundancy for the environment. Requires VNet integration and a region with availability zones."
  default     = false
}

# ---------------------------------------------------------------------------
# Container Apps
# ---------------------------------------------------------------------------

variable "apps" {
  sensitive = true
  type = list(object({
    name          = string
    image         = string
    cpu           = optional(number, 0.25)
    memory        = optional(string, "0.5Gi")
    revision_mode = optional(string, "Single")
    min_replicas  = optional(number, 1)
    max_replicas  = optional(number, 3)

    # Plaintext env vars; use secret_name to reference a secret defined in secrets[]
    env = optional(list(object({
      name        = string
      value       = optional(string) # plaintext value
      secret_name = optional(string) # name of an entry in secrets[] below
    })), [])

    # Secrets are stored encrypted in the Container Apps runtime.
    # Reference them from env[] via secret_name.
    secrets = optional(list(object({
      name  = string
      value = string
    })), [])

    ingress = optional(object({
      external_enabled = bool
      target_port      = number
    }), null)
  }))
  description = "Container Apps to deploy inside this environment. Use secrets[] for sensitive values and reference them from env[] via secret_name. Set ingress = null for background worker apps that do not serve HTTP traffic."
  default     = []
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to all resources."
  default     = {}
}
