variable "enable" {
  description = "Toggle creation of all Entra ID groups."
  type        = bool
  default     = true
}

variable "groups" {
  description = "List of Entra ID groups to create. Set mail_enabled = true for M365 (Unified) groups."
  type = list(object({
    name               = string
    display_name       = string
    description        = optional(string, null)
    assignable_to_role = optional(bool, false)
    mail_enabled       = optional(bool, false)
    mail_nickname      = optional(string, null)
    member_object_ids  = optional(list(string), [])
    owner_object_ids   = optional(list(string), [])
  }))
  default = []
}
