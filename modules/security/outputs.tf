output "security_contact_email" {
  description = "Configured security contact email."
  value       = try(azurerm_security_center_contact.default[0].email, null)
}
