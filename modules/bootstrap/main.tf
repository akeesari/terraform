# ---------------------------------------------------------------------------
# Data sources
# ---------------------------------------------------------------------------

data "azurerm_client_config" "current" {}

# ---------------------------------------------------------------------------
# Resource Group
# ---------------------------------------------------------------------------

resource "azurerm_resource_group" "this" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

# ---------------------------------------------------------------------------
# Storage Account + Container  (Terraform remote state backend)
# ---------------------------------------------------------------------------

resource "azurerm_storage_account" "this" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.this.name
  location                 = azurerm_resource_group.this.location
  account_tier             = "Standard"
  account_replication_type = split("_", var.storage_account_sku)[1]
  account_kind             = "StorageV2"

  min_tls_version                 = "TLS1_2"
  https_traffic_only_enabled      = true
  allow_nested_items_to_be_public = false # no public blob access on state storage

  blob_properties {
    versioning_enabled = true
  }

  tags = var.tags

  lifecycle {
    # blob_properties may be managed by Azure Policy (soft delete, retention);
    # ignore_changes prevents Terraform fighting Azure-managed defaults.
    ignore_changes = [blob_properties]
  }
}

resource "azurerm_storage_container" "this" {
  name                  = var.storage_container_name
  storage_account_id    = azurerm_storage_account.this.id
  container_access_type = "private"
}

# ---------------------------------------------------------------------------
# Service Principal for Terraform automation
# ---------------------------------------------------------------------------

resource "azuread_application" "terraform" {
  display_name = var.service_principal_name

  lifecycle {
    # Azure AD automatically adds default oauth2_permission_scopes and implicit_grant
    # settings when an application is created. Ignore them to prevent Terraform
    # removing Azure-managed defaults on every plan.
    ignore_changes = [api, web]
  }
}

resource "azuread_service_principal" "terraform" {
  client_id = azuread_application.terraform.client_id
}

resource "azuread_service_principal_password" "terraform" {
  service_principal_id = azuread_service_principal.terraform.id
  # No end_date set — uses the Azure AD tenant's maximum allowed lifetime.
  # To rotate: terraform apply -replace="azuread_service_principal_password.terraform"

  lifecycle {
    # The password value is write-only in Azure AD (not returned by the API).
    # azuread_service_principal_password does not support import — this resource
    # will show as needing creation until the SP password is rotated via Terraform.
  }
}

# KNOWN RISK: Owner at subscription scope allows this SP to re-assign any role to any principal,
# including itself. This is intentional for the bootstrap phase where the SP must be able to
# create role assignments for downstream modules (AKS, Key Vault, Managed Identities, etc.).
#
# Post-bootstrap hardening (tracked follow-up):
#   Replace "Owner" with two narrower roles:
#     - "Contributor"              — resource create/update/delete
#     - "User Access Administrator" — role assignment rights, also at subscription scope
#   This satisfies the least-privilege principle while retaining the ability to assign roles.
#   Requires re-running bootstrap and a targeted role-assignment replace.
resource "azurerm_role_assignment" "terraform_sp_contributor" {
  scope                = "/subscriptions/${var.subscription_id}"
  role_definition_name = "Owner"
  principal_id         = azuread_service_principal.terraform.object_id
}

# ---------------------------------------------------------------------------
# Key Vault  (stores Terraform credentials as secrets)
# ---------------------------------------------------------------------------

resource "azurerm_key_vault" "this" {
  name                = var.key_vault_name
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  rbac_authorization_enabled = false
  purge_protection_enabled   = false # keep false so dev environments can be cleanly destroyed

  tags = var.tags
}

resource "azurerm_key_vault_access_policy" "admin_user" {
  key_vault_id = azurerm_key_vault.this.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = var.admin_user_object_id

  key_permissions         = ["Get", "List"]
  secret_permissions      = ["Get", "List", "Set", "Delete", "Purge", "Recover"]
  certificate_permissions = ["Get", "List"]

  lifecycle {
    # The admin user's access policy was provisioned with broader permissions
    # than what this module configures. Ignore drift so Terraform does not
    # accidentally reduce those permissions on future applies.
    ignore_changes = [key_permissions, secret_permissions, certificate_permissions, storage_permissions]
  }
}

# Access policy — Terraform SP (policy is scoped to the AAD Application object ID)
resource "azurerm_key_vault_access_policy" "terraform_sp" {
  key_vault_id = azurerm_key_vault.this.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azuread_application.terraform.object_id

  key_permissions         = ["Get", "List"]
  secret_permissions      = ["Get", "List"]
  certificate_permissions = []
}

# ---------------------------------------------------------------------------
# Key Vault Secrets  (all 5 credentials consumed by downstream stacks)
# ---------------------------------------------------------------------------

resource "azurerm_key_vault_secret" "tf_subscription_id" {
  name         = "tf-subscription-id"
  value        = data.azurerm_client_config.current.subscription_id
  key_vault_id = azurerm_key_vault.this.id
  depends_on   = [azurerm_key_vault_access_policy.admin_user]

  lifecycle {
    ignore_changes = [tags] # Azure auto-adds file-encoding tag; prevent accidental removal
  }
}

resource "azurerm_key_vault_secret" "tf_client_id" {
  name         = "tf-client-id"
  value        = azuread_application.terraform.client_id
  key_vault_id = azurerm_key_vault.this.id
  depends_on   = [azurerm_key_vault_access_policy.admin_user]

  lifecycle {
    ignore_changes = [tags] # Azure auto-adds file-encoding tag; prevent accidental removal
  }
}

resource "azurerm_key_vault_secret" "tf_client_secret" {
  name         = "tf-client-secret"
  value        = azuread_service_principal_password.terraform.value
  key_vault_id = azurerm_key_vault.this.id
  depends_on   = [azurerm_key_vault_access_policy.admin_user]

  lifecycle {
    # The SP password value is write-only in Azure AD (not returned by the API)
    # and azuread_service_principal_password does not support import.
    # Suppress value diffs so this secret is not replaced when importing into state.
    # Also ignore tags as Azure auto-adds file-encoding tag.
    ignore_changes = [value, tags]
  }
}

resource "azurerm_key_vault_secret" "tf_tenant_id" {
  name         = "tf-tenant-id"
  value        = data.azurerm_client_config.current.tenant_id
  key_vault_id = azurerm_key_vault.this.id
  depends_on   = [azurerm_key_vault_access_policy.admin_user]

  lifecycle {
    ignore_changes = [tags] # Azure auto-adds file-encoding tag; prevent accidental removal
  }
}

resource "azurerm_key_vault_secret" "tf_access_key" {
  name         = "tf-access-key"
  value        = azurerm_storage_account.this.primary_access_key
  key_vault_id = azurerm_key_vault.this.id
  depends_on   = [azurerm_key_vault_access_policy.admin_user]

  lifecycle {
    ignore_changes = [tags] # Azure auto-adds file-encoding tag; prevent accidental removal
  }
}
