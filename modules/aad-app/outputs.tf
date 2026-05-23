output "id" {
  description = "Azure AD application resource ID (alias for application_id — satisfies module convention)."
  value       = try(azuread_application.this[0].id, null)
}

output "application_id" {
  description = "Azure AD application resource ID."
  value       = try(azuread_application.this[0].id, null)
}

output "client_id" {
  description = "Azure AD application (client) ID used in OAuth2 flows."
  value       = try(azuread_application.this[0].client_id, null)
}

output "object_id" {
  description = "Object ID of the Azure AD application."
  value       = try(azuread_application.this[0].object_id, null)
}

output "service_principal_id" {
  description = "Object ID of the service principal associated with this application."
  value       = try(azuread_service_principal.this[0].object_id, null)
}

output "client_secret_value" {
  description = "Client secret value. Store this securely immediately after creation."
  value       = try(azuread_application_password.this[0].value, null)
  sensitive   = true
}

output "client_secret_end_date" {
  description = "RFC3339 timestamp when the current client secret expires."
  value       = try(azuread_application_password.this[0].end_date, null)
}

output "app_role_ids" {
  description = "Map of app role value string to its generated GUID."
  value = length(var.app_roles) > 0 ? {
    for r in var.app_roles : r.value => azuread_application.this[0].app_role_ids[r.value]
  } : {}
}

output "oauth2_permission_scope_ids" {
  description = "Map of OAuth2 scope value string to its generated GUID."
  value = length(var.oauth2_permission_scopes) > 0 ? {
    for s in var.oauth2_permission_scopes : s.value => azuread_application.this[0].oauth2_permission_scope_ids[s.value]
  } : {}
}
