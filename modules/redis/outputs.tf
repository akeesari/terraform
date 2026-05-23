output "id" {
  description = "Redis Cache resource ID."
  value       = one(azurerm_redis_cache.this[*].id)
}

output "name" {
  description = "Redis Cache name."
  value       = one(azurerm_redis_cache.this[*].name)
}

output "hostname" {
  description = "Redis Cache hostname."
  value       = one(azurerm_redis_cache.this[*].hostname)
}

output "ssl_port" {
  description = "Redis Cache TLS port (6380)."
  value       = one(azurerm_redis_cache.this[*].ssl_port)
}

output "primary_access_key" {
  description = "Primary Redis access key."
  value       = one(azurerm_redis_cache.this[*].primary_access_key)
  sensitive   = true
}

output "primary_connection_string" {
  description = "Primary Redis connection string."
  value       = one(azurerm_redis_cache.this[*].primary_connection_string)
  sensitive   = true
}
