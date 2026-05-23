# Security Policy

## Supported Versions

This repository contains Terraform module source code, not a deployed service. Security guidance applies to the modules themselves and to infrastructure deployed using them.

## Reporting a Vulnerability

If you discover a security vulnerability in these modules — for example, a module that allows insecure defaults, exposes secrets in state, or creates overly permissive IAM roles — please **do not open a public GitHub issue**.

Instead, use [GitHub's private vulnerability reporting](https://docs.github.com/en/code-security/security-advisories/guidance-on-reporting-and-writing/privately-reporting-a-security-vulnerability):

1. Go to the **Security** tab of this repository
2. Click **Report a vulnerability**
3. Fill in the details and submit

We aim to acknowledge reports within **5 business days** and to provide a resolution or mitigation plan within **30 days** for confirmed vulnerabilities.

## Security Defaults in These Modules

The modules in this repository enforce the following security baselines. These are **hardcoded** and cannot be overridden by callers:

| Control | Default |
|---|---|
| TLS version | 1.2 minimum on all applicable resources |
| Public blob access | Disabled on all storage accounts |
| Key Vault authorization | RBAC mode (`rbac_authorization_enabled = true`) |
| Azure SQL TDE | Always enabled |
| Redis | TLS 1.2 minimum, non-SSL port disabled |
| App Gateway / Front Door WAF | OWASP 3.2 managed rules (Prevention mode, WAF SKU) |

## What Is NOT Stored in This Repository

- Subscription IDs or Tenant IDs
- Service principal credentials or client secrets
- Access keys or connection strings
- Passwords or API tokens
- `.tfvars` files containing environment-specific values

These are excluded by `.gitignore` and must be supplied at runtime via environment variables (`ARM_*`) or Azure Key Vault references.

## Dependency Security

Helm chart versions are pinned in module variables. Review release notes for upstream charts before upgrading versions in a pull request.
