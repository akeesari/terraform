# CLAUDE.md — terraform

Top-level guidance for Claude Code working in this repository.

## Repository Layout

```
terraform/
├── modules/          # All reusable Terraform modules (see modules/CLAUDE.md)
│   ├── <module>/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── charts/       # Helm chart modules (Kubernetes in-cluster tooling)
├── .github/
│   ├── workflows/    # GitHub Actions CI
│   └── copilot-instructions.md
├── README.md
├── CONTRIBUTING.md
├── SECURITY.md
└── LICENSE
```

## Module Rules (summary — full detail in modules/CLAUDE.md)

- Exactly **three files** per module: `main.tf`, `variables.tf`, `outputs.tf`
- Primary resource named `this`; all resources accept `tags = var.tags`
- Security defaults **hardcoded** — never expose `minimum_tls_version`, `public_network_access`, or `transparent_data_encryption` as variables
- Secrets: `sensitive = true` on variables and outputs; source from Key Vault, not plain strings
- No `lifecycle { prevent_destroy = true }` inside modules — lock is on the resource group

## Provider & Version Constraints

- Terraform `>= 1.5`
- `azurerm` — use `azurerm_` prefix resources
- `azuread` — use `azuread_` prefix resources
- `kubernetes` / `helm` — for chart modules only

## Naming Convention

- Module directories: `kebab-case`
- Resources inside modules: snake_case, named `this` for the primary resource
- Variable examples in descriptions: use `myapp` as the placeholder project name (not any real org name)

## Authentication

- Never hardcode subscription IDs, tenant IDs, client secrets, or access keys in any `.tf` file
- Use `data "azurerm_client_config" "current" {}` to read tenant/subscription at plan time
- Credentials for CI come from GitHub Actions OIDC federation — no long-lived secrets in workflows

## Security Checklist Before Commit

- [ ] No real email addresses, domain names, or org names in any file
- [ ] No GUIDs that are subscription IDs or tenant IDs (public Azure policy IDs are fine)
- [ ] All `sensitive` variables/outputs marked correctly
- [ ] `.tfvars` files are gitignored (they are — see `.gitignore`)
- [ ] No hardcoded passwords, tokens, or connection strings

## Running Locally

```bash
terraform init
terraform fmt -recursive
terraform validate
terraform plan -out=tfplan
terraform apply tfplan
```

## CI

GitHub Actions runs `terraform fmt -check` and `terraform validate` on every PR. Fix formatting with `terraform fmt -recursive` before pushing.
