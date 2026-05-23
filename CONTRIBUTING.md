# Contributing

Thank you for contributing to this Terraform module library.

## Before You Start

- Check existing modules in `modules/` — you may be able to extend one rather than creating a new one.
- Open an issue to discuss a new module or significant change before writing code.

## Module Conventions

All modules follow the rules defined in [modules/CLAUDE.md](modules/CLAUDE.md) and [.github/copilot-instructions.md](.github/copilot-instructions.md). Read those before writing any code.

**Key rules:**
- Exactly three files per module: `main.tf`, `variables.tf`, `outputs.tf`
- Primary resource named `this`
- Security defaults hardcoded (TLS version, public access, etc.)
- Secrets marked `sensitive = true`
- Every variable and output has a `description`

## Development Workflow

### 1. Fork and clone

```bash
git clone https://github.com/<your-fork>/terraform.git
cd terraform
```

### 2. Create a branch

```bash
git checkout -b feat/my-new-module
```

### 3. Write your module

Follow the structure in an existing module (e.g. `modules/redis/`) as a reference.

### 4. Format and validate

```bash
terraform fmt -recursive modules/
terraform -chdir=modules/<your-module> init -backend=false
terraform -chdir=modules/<your-module> validate
```

### 5. Open a pull request

- Title: `feat(module-name): short description` or `fix(module-name): short description`
- Describe what the module does, what Azure service it wraps, and any non-obvious design decisions
- CI will run `terraform fmt -check` and `terraform validate` automatically

## Security Requirements

Before submitting a PR, confirm:

- [ ] No real email addresses, domain names, or org-specific strings in any file
- [ ] No subscription IDs, tenant IDs, or GUIDs that are not public Azure resource IDs
- [ ] All sensitive variables/outputs marked `sensitive = true`
- [ ] No hardcoded passwords, tokens, connection strings, or access keys
- [ ] `.tfvars` files are not committed (they are gitignored)

## Commit Style

```
feat(aks): add KEDA scaler support
fix(keyvault): correct network acl default action
docs(readme): add postgres module to reference table
```

## Code Review

All PRs require at least one review. Reviewers will check:

1. Module follows the three-file structure
2. Security defaults are hardcoded, not variable
3. Outputs include at minimum `id` and `name`
4. No sensitive information is committed

## Questions

Open a [GitHub Discussion](../../discussions) for questions about design or usage.
