output "id" {
  description = "Front Door profile resource ID."
  value       = azurerm_cdn_frontdoor_profile.this.id
}

output "name" {
  description = "Front Door profile name."
  value       = azurerm_cdn_frontdoor_profile.this.name
}

output "endpoint_id" {
  description = "Default Front Door endpoint resource ID."
  value       = azurerm_cdn_frontdoor_endpoint.this.id
}

output "endpoint_hostname" {
  description = "Default Front Door endpoint hostname (e.g. <name>-xxxx.z01.azurefd.net)."
  value       = azurerm_cdn_frontdoor_endpoint.this.host_name
}

output "origin_group_id" {
  description = "Front Door origin group resource ID."
  value       = azurerm_cdn_frontdoor_origin_group.this.id
}

output "waf_policy_id" {
  description = "WAF firewall policy resource ID. Null when enable_waf = false."
  value       = one(azurerm_cdn_frontdoor_firewall_policy.this[*].id)
}
