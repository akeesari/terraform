variable "enable" {
  type        = bool
  description = "Toggle creation of the Azure AD application and all related objects."
  default     = true
}

variable "display_name" {
  type        = string
  description = "Display name of the Azure AD application registration."
}

variable "identifier_uris" {
  type        = list(string)
  description = "Application ID URIs (required when the app exposes an API)."
  default     = []
}

variable "web_redirect_uris" {
  type        = list(string)
  description = "OAuth2 redirect URIs for the confidential (web) client flow."
  default     = []
}

variable "spa_redirect_uris" {
  type        = list(string)
  description = "OAuth2 redirect URIs for the public single-page application (PKCE) flow."
  default     = []
}

variable "enable_group_claims" {
  type        = bool
  description = "Emit SecurityGroup membership claims in access/ID tokens."
  default     = false
}

variable "create_client_secret" {
  type        = bool
  description = "Whether to create a client secret (application password) for the app registration."
  default     = true
}

variable "secret_end_date_relative" {
  type        = string
  description = "Relative duration for client secret validity (e.g. '8760h' = 1 year)."
  default     = "8760h"
}

variable "optional_claims_id_token" {
  type        = list(string)
  description = "Optional claims to include in ID tokens (e.g. ['email', 'upn'])."
  default     = []
}

variable "optional_claims_access_token" {
  type        = list(string)
  description = "Optional claims to include in access tokens."
  default     = []
}

variable "app_roles" {
  type = list(object({
    id                   = string # Stable GUID (generate once with uuidgen)
    display_name         = string
    allowed_member_types = list(string) # e.g. ["User"] or ["Application"]
    description          = string
    value                = string # Role value string
    enabled              = optional(bool, true)
  }))
  description = "Custom application roles exposed by this app registration."
  default     = []
}

variable "requested_access_token_version" {
  type        = number
  description = "Access token version for the app's API endpoint (1 or 2)."
  default     = 2
  validation {
    condition     = contains([1, 2], var.requested_access_token_version)
    error_message = "requested_access_token_version must be 1 or 2."
  }
}

variable "oauth2_permission_scopes" {
  type = list(object({
    id                         = string # Stable GUID per scope
    admin_consent_display_name = string
    admin_consent_description  = string
    user_consent_display_name  = string
    user_consent_description   = string
    value                      = string # Scope value string (e.g. "user_impersonation")
    enabled                    = optional(bool, true)
  }))
  description = "OAuth2 permission scopes exposed by this app's API."
  default     = []
}
