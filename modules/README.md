# Terraform Modules

Reusable Terraform modules for the `infra` repository. Each module is self-contained with exactly three files — `main.tf`, `variables.tf`, `outputs.tf` — and follows the conventions defined in [`.github/instructions/terraform-modules.instructions.md`](../../.github/instructions/terraform-modules.instructions.md).

---

## Module Reference

| Module | Azure Service | Key Features |
|---|---|---|
| [`aad_app`](./aad_app/) | Azure AD App Registration | App registration, service principal, client secret, app roles, OAuth2 scopes |
| [`acr`](./acr/) | Container Registry | SKU selection, admin account toggle, geo-replication ready |
| [`aks`](./aks/) | Kubernetes Service | System + worker node pools, autoscaler, Workload Identity, KEDA/VPA, Web App Routing, Defender, maintenance windows |
| [`app_service`](./app_service/) | App Service | Linux Service Plan, frontend + API web apps, App Insights integration, per-env settings |
| [`azsql`](./azsql/) | Azure SQL | SQL Server + databases, Entra-only auth, firewall rules, TLS 1.2, TDE enforced |
| [`budget`](./budget/) | Cost Management | Monthly budget scoped to a resource group, 50 / 80 / 100 % email alert thresholds |
| [`dns_record`](./dns_record/) | DNS Records | A, CNAME, and TXT records via `for_each`; per-record TTL override |
| [`dns_zone`](./dns_zone/) | Public DNS Zone | Zone creation, optional parent NS delegation record |
| [`foundry`](./foundry/) | Azure AI Foundry | AI Foundry hub + project, AI Search, OpenAI model deployments, Anthropic model deployments, storage connections |
| [`keyvault`](./keyvault/) | Key Vault | RBAC mode, network ACLs, private endpoint, CMK keys (Postgres + Storage), role assignments, diagnostic settings |
| [`mgmt_groups`](./mgmt_groups/) | Management Groups | Tenant-level management group hierarchy, subscription placement |
| [`monitoring`](./monitoring/) | Monitor / Log Analytics | Log Analytics Workspace, Application Insights (workspace-based), Action Group with email receivers |
| [`openai`](./openai/) | Azure OpenAI | Cognitive account, model deployments map, private network option |
| [`policy`](./policy/) | Azure Policy | MCSB audit, allowed locations, tag inheritance, activity log diagnostics — subscription scope |
| [`postgres`](./postgres/) | PostgreSQL Flexible Server | Flexible Server, multiple databases, HA mode, maintenance window, CPU / memory / storage / connection alerts |
| [`private_endpoint`](./private_endpoint/) | Private Endpoint | Private DNS zone, VNet link, private endpoint NIC — one module call per service |
| [`redis`](./redis/) | Redis Cache | Cache SKU, maxmemory policy, TLS 1.2 hardcoded |
| [`resource_group`](./resource_group/) | Resource Group | Resource group, CanNotDelete management lock, merged tag strategy |
| [`security`](./security/) | Defender for Cloud | CSPM, Defender plans for Servers / Containers / SQL / Key Vault / Storage / App Service, security contact |
| [`bastion`](./bastion/) | Azure Bastion | Standard/Basic SKU, static public IP, subnet association, tunneling + file copy + IP connect (Standard only) |
| [`cosmos_db`](./cosmos_db/) | Cosmos DB | Core SQL account, Entra-only auth, automatic failover, multi-region geo-locations, autoscale/manual SQL databases, Periodic or Continuous backup |
| [`app_gateway`](./app_gateway/) | Application Gateway | Standard_v2/WAF_v2 SKU, autoscaling, public IP, backend pools, HTTP/HTTPS listeners, routing rules, health probes, HTTP→HTTPS redirect, OWASP 3.2 WAF (Prevention), TLS 1.2 hardcoded |
| [`frontdoor`](./frontdoor/) | Azure Front Door | Standard/Premium profile, endpoint, origin group, origins, HTTPS-only route, optional WAF policy with managed rule sets (Premium) |
| [`grafana`](./grafana/) | Azure Managed Grafana | Grafana 9/10 workspace, system-assigned identity, Monitoring Reader role assignment, zone redundancy option |
| [`nat_gateway`](./nat_gateway/) | NAT Gateway | Standard public IP prefix, NAT Gateway, subnet associations — deterministic outbound IPs for AKS / App Service |
| [`storage`](./storage/) | Storage Account | Standard account, replication type, anonymous access disabled, TLS 1.2 hardcoded, soft delete (7 days), dynamic containers and queues via variables |
| [`vnet`](./vnet/) | Virtual Network | VNet with four opinionated subnets (AKS `/20`, app `/22`, data `/22`, shared `/24`), NSGs per subnet |
| [`service_bus`](./service_bus/) | Service Bus | Standard/Premium namespace, queues with dead-lettering defaults, topics, Entra-only auth (SAS keys disabled), TLS 1.2 hardcoded |
| [`event_hub`](./event_hub/) | Event Hub | Standard/Premium namespace, multiple hubs, consumer groups, auto-inflate (Standard), Entra-only auth, TLS 1.2 hardcoded |
| [`container_apps`](./container_apps/) | Container Apps | Container Apps Environment, multiple apps via variable, system-assigned identity, optional VNet integration and internal load balancer |
| [`function_app`](./function_app/) | Azure Functions | Linux Function App (Premium EP1/EP2/EP3 or Consumption Y1), backing storage with managed identity, role assignments for blob/queue/table, multi-runtime support |
| [`apim`](./apim/) | API Management | Developer/Basic/Standard/Premium SKU, system-assigned identity, optional VNet integration (External/Internal), App Insights logger, diagnostic settings, named values |

---

## Chart Modules (Kubernetes / Helm)

In-cluster tooling deployed via Helm. Full reference: [`charts/README.md`](./charts/README.md).

| Module | Tool | Purpose |
|---|---|---|
| [`charts/argocd`](./charts/argocd/) | Argo CD | GitOps controller with optional app-of-apps pattern |
| [`charts/blackbox-exporter`](./charts/blackbox-exporter/) | Blackbox Exporter | HTTP/SSL endpoint probing wired to kube-prometheus-stack |
| [`charts/cert_manager`](./charts/cert_manager/) | cert-manager | TLS certificate automation via Let's Encrypt |
| [`charts/grafana-loki`](./charts/grafana-loki/) | Loki + Promtail + Grafana | In-cluster log aggregation and visualization |
| [`charts/ingress_nginx`](./charts/ingress_nginx/) | ingress-nginx | Kubernetes L7 ingress with Azure Load Balancer |
| [`charts/kube-prometheus-stack`](./charts/kube-prometheus-stack/) | kube-prometheus-stack | Prometheus Operator, Prometheus, Alertmanager |
| [`charts/pgadmin`](./charts/pgadmin/) | pgAdmin 4 | PostgreSQL web admin with pre-wired server definitions |
| [`charts/prometheuscrds`](./charts/prometheuscrds/) | prometheus-operator-crds | Standalone CRD bootstrap (deploy before kube-prometheus-stack) |

---

## Conventions

- **Feature flags** — most modules support an `enable_<resource>` variable (default `false`) to opt in to optional sub-resources without forking the module.
- **Lifecycle protection** — all persistent resources carry `lifecycle { prevent_destroy = true }` to guard against accidental deletion.
- **RBAC over access policies** — Key Vault uses `rbac_authorization_enabled = true`; no legacy access policies are used anywhere.
- **Hardcoded security defaults** — `minimum_tls_version`, `anonymous access`, and `transparent_data_encryption` are never exposed as variables.
- **Tags** — every module accepts `tags = map(string)` (default `{}`); some modules merge additional system tags internally.

---

## Roadmap

### Phase 1 — Existing Module Improvements

The following improvements keep modules simple and consistent with existing conventions. One module at a time.

| Module | Change |
|---|---|
| [`storage`](./storage/) | Replace hardcoded `models / datasets / outputs` containers with a dynamic `containers` variable (`list(string)`) and add an optional `queues` variable. Remove the coupling to AI-specific names so the module is general-purpose. |
| [`monitoring`](./monitoring/) | Add `local_authentication_disabled` variable (default `false`) to the `azurerm_log_analytics_workspace` resource. When `true`, forces Entra-only auth and disables shared-key access. It maps directly to an Azure security recommendation in Defender for Cloud. |
| [`acr`](./acr/) | Add optional `geo_replication_locations` (`list(string)`, default `[]`) and `enable_network_rule_set` flag with `ip_rules` / `subnet_ids` inputs. Apply only when `sku = "Premium"`. Gate behind `enable_*` flags to keep non-Premium callers untouched. |

> **Note:** `keyvault` — `rbac_authorization_enabled` is intentionally hard-coded to `true` (RBAC over access policies is a non-negotiable security default). No change needed here.

---

### Phase 2 — New Modules

Services not yet covered by existing modules.

| Module | Azure Service | Priority | Why It's Needed |
|---|---|---|---|
| `service_bus` ✅ | Service Bus | High | Namespace + queues / topics / subscriptions — async messaging backbone used in every event-driven stack |
| `event_hub` ✅ | Event Hub | High | Namespace + hubs + consumer groups — high-throughput telemetry and log ingestion |
| `container_apps` ✅ | Container Apps | High | Container Apps Environment + Apps — serverless containers, lighter-weight alternative to AKS |
| `function_app` ✅ | Azure Functions | High | Flex Consumption or Premium plan — event-driven serverless compute |
| `apim` ✅ | API Management | High | API gateway with rate limiting, auth policies, and developer portal — missing from both repos |
| `mysql` | MySQL Flexible Server | Medium | Flexible Server + databases — counterpart to the existing `postgres` module |
| `vnet_peering` | VNet Peering | Medium | Hub-spoke or cross-stack VNet peering — currently each stack is network-isolated with no peering wired in |
| `static_app` | Static Web Apps | Medium | Static Web App + optional API backend — frontend hosting for SPAs and documentation sites |
| `ai_search` | Azure AI Search | Medium | Search service — direct companion to the existing `foundry` module for RAG workloads |

