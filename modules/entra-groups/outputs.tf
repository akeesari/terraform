output "group_ids" {
  description = "Map of group name key to object ID."
  value       = { for k, g in azuread_group.this : k => g.object_id }
}

output "group_display_names" {
  description = "Map of group name key to display name."
  value       = { for k, g in azuread_group.this : k => g.display_name }
}
