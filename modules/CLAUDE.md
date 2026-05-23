# CLAUDE.md — terraform/modules

Applies to all modules under `terraform/modules/`. See repo root `CLAUDE.md` for general workflow and guardrails.

## File Structure
Exactly three files per module — no extras:
- `main.tf` — resources
- `variables.tf` — inputs
- `outputs.tf` — outputs

## Naming
Module directories use `kebab-case` (e.g. `private-endpoint`, `resource-group`).

## main.tf
- Primary resource always named `this`
- All resources accept `tags = var.tags`
- Hardcode security defaults (e.g. `minimum_tls_version = "1.2"`) — never expose them as variables
- Do NOT add `lifecycle { prevent_destroy = true }` — deletion protection is handled by the parent resource group lock
- Add `data "azurerm_client_config" "current" {}` when `tenant_id` is needed

## variables.tf
- Required (no default): `name`, `resource_group_name`, `location`
- Always include `tags = map(string)` with `default = {}`
- Every variable needs a `description`; add `validation` blocks for constrained inputs (SKUs, regex, length)
- Mark secrets `sensitive = true`; never include `sp_*` variables (stack-level only)

## outputs.tf
- Always output `id` and `name` at minimum
- Every output needs a `description`; mark secret values `sensitive = true`

## Security Defaults
- Key Vault: `rbac_authorization_enabled = true`, `network_acls { default_action = "Deny" }`
- Redis: `minimum_tls_version = "1.2"`
- Management locks: `count`-gated via an `enable_management_lock` variable
