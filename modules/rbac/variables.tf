variable "enable" {
  description = "Toggle creation of all role assignments."
  type        = bool
  default     = true
}

variable "role_assignments" {
  description = "List of RBAC role assignments to create."
  type = list(object({
    scope                            = string # Full resource ID, RG ID, or subscription scope
    role_definition_name             = string # e.g. "Contributor", "Reader", "AcrPull"
    principal_id                     = string # Object ID of user, group, or service principal
    skip_service_principal_aad_check = optional(bool, false)
    condition                        = optional(string, null) # ABAC condition expression
  }))
  default = []
}
