variable "enable_security" {
  description = "Set to true to activate Defender for Cloud plans and security contact."
  type        = bool
  default     = false
}

variable "security_contact_email" {
  description = "Email address for Defender for Cloud security alerts."
  type        = string
}

variable "enable_defender_for_servers" {
  description = "Enable Defender for Servers."
  type        = bool
  default     = false
}

variable "defender_servers_subplan" {
  description = "Defender for Servers sub-plan: P1 (agentless-only) or P2 (full MDE integration)."
  type        = string
  default     = "P2"

  validation {
    condition     = contains(["P1", "P2"], var.defender_servers_subplan)
    error_message = "defender_servers_subplan must be P1 or P2."
  }
}

variable "enable_defender_for_app_service" {
  description = "Enable Defender for App Service."
  type        = bool
  default     = false
}

variable "enable_defender_for_containers" {
  description = "Enable Defender for Containers."
  type        = bool
  default     = false
}

variable "enable_defender_for_databases" {
  description = "Enable Defender for Databases (SQL + OSS)."
  type        = bool
  default     = false
}

variable "enable_defender_for_key_vault" {
  description = "Enable Defender for Key Vault (recommended for prod, low cost)."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
  default     = {}
}
