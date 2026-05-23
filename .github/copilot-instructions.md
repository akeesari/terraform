# GitHub Copilot Instructions — Azure Terraform Modules

These instructions guide Copilot suggestions when working in this repository.

## What This Repo Is

A library of reusable Terraform modules for Azure infrastructure. Each module lives under `modules/<name>/` and contains exactly three files: `main.tf`, `variables.tf`, `outputs.tf`.

## Module Structure Rules

When generating or completing module code, follow these rules:

### main.tf
- Name the primary resource `this` (e.g. `resource "azurerm_storage_account" "this"`)
- Every resource must include `tags = var.tags`
- Hardcode security defaults — never expose them as variables:
  - `min_tls_version = "TLS1_2"` or `minimum_tls_version = "1.2"`
  - `allow_nested_items_to_be_public = false`
  - `public_network_access_enabled = false` (unless the module explicitly opts in)
  - `transparent_data_encryption_enabled = true`
- Use `data "azurerm_client_config" "current" {}` when `tenant_id` or `subscription_id` is needed at plan time — never hardcode them

### variables.tf
- Required variables (no default): `name`, `resource_group_name`, `location`
- Always include: `variable "tags" { type = map(string); default = {} }`
- Every variable needs a `description`
- Mark secrets `sensitive = true`
- Use `validation` blocks for constrained inputs (SKUs, regex, length limits)
- Use `myapp` as the placeholder name in description examples — never a real org name

### outputs.tf
- Always output at minimum: `id`, `name`
- Every output needs a `description`
- Mark secret values `sensitive = true`

## Security Rules

- **Never hardcode**: subscription IDs, tenant IDs, client secrets, passwords, access keys, connection strings, tokens, or email addresses belonging to a real organization
- **Secrets in Key Vault**: sensitive values are stored in Key Vault and referenced via `azurerm_key_vault_secret` data sources, not passed as plain string variables
- **RBAC over access policies**: Key Vault must use `rbac_authorization_enabled = true`
- **Network defaults**: storage accounts and Key Vaults default to `network_acls { default_action = "Deny" }`
- **Sensitive outputs**: any output that exposes a secret value must set `sensitive = true`

## Naming Conventions

- Module directories: `kebab-case` (e.g. `private-endpoint`, `resource-group`)
- Resources: snake_case; primary resource always named `this`
- Variables: snake_case descriptive names
- Example values in descriptions: use `myapp-dev`, `myapp-prod` — not real project or org names

## Common Patterns

### Feature flags
```hcl
variable "enable_private_endpoint" {
  description = "Create a private endpoint for this resource."
  type        = bool
  default     = false
}

resource "azurerm_private_endpoint" "this" {
  count = var.enable_private_endpoint ? 1 : 0
  # ...
}
```

### Dynamic blocks with optional collections
```hcl
variable "ip_rules" {
  description = "List of IP ranges allowed through the network ACL."
  type        = list(string)
  default     = []
}

dynamic "ip_rule" {
  for_each = var.ip_rules
  content {
    ip_address = ip_rule.value
  }
}
```

### Sensitive outputs
```hcl
output "primary_access_key" {
  description = "Primary access key. Store in Key Vault; do not log."
  value       = azurerm_storage_account.this.primary_access_key
  sensitive   = true
}
```

## What NOT to Generate

- Do not add `lifecycle { prevent_destroy = true }` inside modules — deletion protection belongs on the resource group lock
- Do not create `terraform.tfvars` files — they are gitignored for security reasons
- Do not add a fourth file to a module (e.g. `locals.tf`, `providers.tf`) unless the module is a chart module that genuinely needs a separate provider block
- Do not hardcode environment names, region names, or subscription/tenant IDs in resource definitions
