output "role_assignment_ids" {
  description = "Map of role assignment key to resource ID."
  value       = { for k, r in azurerm_role_assignment.this : k => r.id }
}
