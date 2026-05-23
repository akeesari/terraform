# Azure Terraform Modules

A collection of reusable, opinionated Terraform modules for deploying production-grade Azure infrastructure. Each module is self-contained, follows consistent conventions, and encodes security defaults so callers cannot accidentally weaken them.

## Overview

| Category | Modules |
|---|---|
| **Networking** | `vnet`, `networking`, `nat-gateway`, `private-endpoint`, `dns-zone`, `dns-record`, `frontdoor`, `app-gateway` |
| **Compute** | `aks`, `app-service`, `function-app`, `container-apps`, `bastion` |
| **Data** | `postgres`, `azsql`, `cosmos-db`, `redis`, `storage`, `event-hub`, `service-bus` |
| **Identity & Security** | `aad-app`, `entra-groups`, `rbac`, `keyvault`, `security`, `bootstrap` |
| **AI / ML** | `openai`, `foundry` |
| **Observability** | `monitoring`, `grafana`, `appinsights` |
| **Platform** | `resource-group`, `budget`, `management-groups`, `policy-assignments`, `acr`, `apim` |
| **Kubernetes / Helm** | `charts/argocd`, `charts/cert-manager`, `charts/ingress-nginx`, `charts/kube-prometheus-stack`, `charts/grafana-loki`, `charts/blackbox-exporter`, `charts/pgadmin`, `charts/prometheuscrds`, `charts/otel-collector`, `charts/otel-operator` |

Full module reference: [modules/README.md](modules/README.md)

---

## Prerequisites

| Tool | Minimum Version | Purpose |
|---|---|---|
| [Terraform](https://developer.hashicorp.com/terraform/downloads) | `>= 1.5` | Infrastructure provisioning |
| [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) | `>= 2.50` | Authentication |
| [kubectl](https://kubernetes.io/docs/tasks/tools/) | `>= 1.27` | AKS cluster access |
| [Helm](https://helm.sh/docs/intro/install/) | `>= 3.12` | Chart deployments |

---

## Getting Started

### 1. Authenticate

```bash
az login
az account set --subscription "<your-subscription-id>"
```

### 2. Bootstrap Remote State

Use the `bootstrap` module once per environment to create the storage account and service principal that all other stacks will use:

```hcl
module "bootstrap" {
  source = "./modules/bootstrap"

  resource_group_name    = "rg-terraform-state"
  location               = "australiaeast"
  storage_account_name   = "stterraformstate"
  storage_container_name = "tfstate"
  service_principal_name = "sp-terraform"
  key_vault_name         = "kv-terraform-state"
  admin_user_object_id   = "<your-aad-object-id>"
  subscription_id        = "<your-subscription-id>"
}
```

### 3. Configure a Backend

After bootstrap, configure Terraform to use the remote state backend:

```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "stterraformstate"
    container_name       = "tfstate"
    key                  = "mystack.tfstate"
    # Authenticate via ARM_ACCESS_KEY env var or ARM_CLIENT_ID + ARM_CLIENT_SECRET + ARM_TENANT_ID
  }
}
```

### 4. Use a Module

```hcl
module "resource_group" {
  source = "./modules/resource-group"

  name     = "rg-myapp-dev"
  location = "australiaeast"
  tags     = { environment = "dev", project = "myapp" }
}

module "networking" {
  source = "./modules/networking"

  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  # ...
}
```

---

## Module Conventions

- **Three files per module** — `main.tf`, `variables.tf`, `outputs.tf`. No extras.
- **Primary resource** is always named `this`.
- **Security defaults are hardcoded** — `minimum_tls_version`, `public_access`, and `transparent_data_encryption` are never exposed as variables. Callers cannot weaken them.
- **All resources accept `tags`** — `tags = map(string)` with `default = {}`.
- **Secrets marked sensitive** — all secret outputs set `sensitive = true` and are sourced from Key Vault, not passed as plain strings.
- **RBAC over access policies** — Key Vault uses `rbac_authorization_enabled = true` throughout.
- **No `prevent_destroy` in modules** — deletion protection is handled at the resource group level via a management lock.

---

## Security Design

- Secrets are never stored in `.tfvars` files or Terraform state in plaintext where avoidable. Use Key Vault references.
- The `bootstrap` module creates a dedicated service principal stored in Key Vault; downstream stacks read credentials from there.
- Network access defaults to `"Deny"` on Key Vaults and storage accounts. Private endpoints are preferred over public access.
- Azure Policy assignments (`policy-assignments` module) enforce allowed locations, tag inheritance, and activity log diagnostics at subscription scope.

See [SECURITY.md](SECURITY.md) for the vulnerability disclosure policy.

---

## CI / CD

A GitHub Actions workflow runs `terraform fmt -check` and `terraform validate` on every pull request. See [.github/workflows/terraform-validate.yml](.github/workflows/terraform-validate.yml).

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

---

## License

[Apache 2.0](LICENSE)
