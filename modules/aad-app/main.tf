locals {
  optional_claims_id     = [for c in var.optional_claims_id_token : { name = c }]
  optional_claims_access = [for c in var.optional_claims_access_token : { name = c }]
}

resource "azuread_application" "this" {
  count        = var.enable ? 1 : 0
  display_name = var.display_name

  identifier_uris = length(var.identifier_uris) > 0 ? var.identifier_uris : null

  web {
    redirect_uris = var.web_redirect_uris
  }

  single_page_application {
    redirect_uris = var.spa_redirect_uris
  }

  optional_claims {
    dynamic "id_token" {
      for_each = local.optional_claims_id
      content {
        name = id_token.value.name
      }
    }
    dynamic "access_token" {
      for_each = local.optional_claims_access
      content {
        name = access_token.value.name
      }
    }
  }

  group_membership_claims = var.enable_group_claims ? ["SecurityGroup"] : null

  dynamic "app_role" {
    for_each = var.app_roles
    content {
      id                   = app_role.value.id
      allowed_member_types = app_role.value.allowed_member_types
      description          = app_role.value.description
      display_name         = app_role.value.display_name
      enabled              = try(app_role.value.enabled, true)
      value                = app_role.value.value
    }
  }

  api {
    requested_access_token_version = var.requested_access_token_version

    dynamic "oauth2_permission_scope" {
      for_each = var.oauth2_permission_scopes
      content {
        id                         = oauth2_permission_scope.value.id
        admin_consent_display_name = oauth2_permission_scope.value.admin_consent_display_name
        admin_consent_description  = oauth2_permission_scope.value.admin_consent_description
        user_consent_display_name  = oauth2_permission_scope.value.user_consent_display_name
        user_consent_description   = oauth2_permission_scope.value.user_consent_description
        value                      = oauth2_permission_scope.value.value
        enabled                    = try(oauth2_permission_scope.value.enabled, true)
      }
    }
  }
}

resource "azuread_service_principal" "this" {
  count     = var.enable ? 1 : 0
  client_id = azuread_application.this[0].client_id
}

resource "azuread_application_password" "this" {
  count          = var.enable && var.create_client_secret ? 1 : 0
  application_id = azuread_application.this[0].id
  display_name   = "terraform-generated"
  end_date       = timeadd(timestamp(), var.secret_end_date_relative)

  lifecycle {
    # end_date is computed from timestamp() on every plan; ignore_changes prevents
    # Terraform from re-creating the secret on each run. The trade-off: the expiry
    # is frozen at creation time and will not self-rotate.
    #
    # Rotation runbook — run this when the secret is near expiry:
    #   terraform apply -replace='module.<name>.azuread_application_password.this[0]'
    #
    # Long-term: consider replacing client secrets with Federated Credentials
    # (workload identity) — these never expire and require no rotation.
    ignore_changes = [end_date]
  }
}
