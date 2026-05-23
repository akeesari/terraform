output "a_record_fqdns" {
  description = "Map of A record names to their fully qualified domain names."
  value       = { for k, v in azurerm_dns_a_record.this : k => v.fqdn }
}

output "cname_record_fqdns" {
  description = "Map of CNAME record names to their fully qualified domain names."
  value       = { for k, v in azurerm_dns_cname_record.this : k => v.fqdn }
}

output "txt_record_fqdns" {
  description = "Map of TXT record names to their fully qualified domain names."
  value       = { for k, v in azurerm_dns_txt_record.this : k => v.fqdn }
}
