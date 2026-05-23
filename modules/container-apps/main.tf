# ==============================================================================
# Container Apps Environment
# ==============================================================================
resource "azurerm_container_app_environment" "this" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name

  log_analytics_workspace_id = var.log_analytics_workspace_id

  # VNet integration: provide infrastructure_subnet_id to deploy into a VNet.
  # The subnet must be delegated to Microsoft.App/environments and be at least /23.
  infrastructure_subnet_id       = var.infrastructure_subnet_id
  internal_load_balancer_enabled = var.infrastructure_subnet_id != null ? var.internal_load_balancer_enabled : false
  zone_redundancy_enabled        = var.zone_redundancy_enabled

  tags = var.tags

  lifecycle {
    ignore_changes = [tags["CreatedDate"], tags["LastModified"]]
  }
}

# ==============================================================================
# Container Apps
# ==============================================================================
resource "azurerm_container_app" "this" {
  for_each = { for app in var.apps : app.name => app }

  name                         = each.key
  resource_group_name          = var.resource_group_name
  container_app_environment_id = azurerm_container_app_environment.this.id
  revision_mode                = each.value.revision_mode
  tags                         = var.tags

  # System-assigned identity lets the app pull images from ACR and access
  # other Azure resources without storing credentials in app config.
  identity {
    type = "SystemAssigned"
  }

  # Secrets are encrypted at rest in the Container Apps runtime.
  # Reference them from env[] entries via secret_name.
  dynamic "secret" {
    for_each = each.value.secrets
    content {
      name  = secret.value.name
      value = secret.value.value
    }
  }

  template {
    min_replicas = each.value.min_replicas
    max_replicas = each.value.max_replicas

    container {
      name   = each.key
      image  = each.value.image
      cpu    = each.value.cpu
      memory = each.value.memory

      dynamic "env" {
        for_each = each.value.env
        content {
          name        = env.value.name
          value       = env.value.secret_name == null ? env.value.value : null
          secret_name = env.value.secret_name
        }
      }
    }
  }

  # Ingress is optional — omit for background worker apps with no HTTP traffic.
  dynamic "ingress" {
    for_each = each.value.ingress != null ? [each.value.ingress] : []
    content {
      external_enabled = ingress.value.external_enabled
      target_port      = ingress.value.target_port

      traffic_weight {
        percentage      = 100
        latest_revision = true
      }
    }
  }

  lifecycle {
    ignore_changes = [tags["CreatedDate"], tags["LastModified"]]
  }
}
