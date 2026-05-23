# ==============================================================================
# Azure Managed Grafana
# ==============================================================================
resource "azurerm_dashboard_grafana" "this" {
  name                              = var.name
  resource_group_name               = var.resource_group_name
  location                          = var.location
  grafana_major_version             = var.grafana_major_version
  sku                               = var.sku
  zone_redundancy_enabled           = var.zone_redundancy_enabled
  api_key_enabled                   = var.api_key_enabled
  deterministic_outbound_ip_enabled = var.deterministic_outbound_ip_enabled
  public_network_access_enabled     = var.public_network_access_enabled
  tags                              = var.tags

  # System-assigned managed identity lets Grafana authenticate to Azure Monitor,
  # Log Analytics, and Prometheus without storing credentials.
  identity {
    type = "SystemAssigned"
  }

  lifecycle {
    ignore_changes = [tags["CreatedDate"], tags["LastModified"]]
  }
}

# ==============================================================================
# Monitoring Reader role assignment
# Grants the Grafana managed identity read access to Azure Monitor metrics and
# Log Analytics workspaces within the target scope.
# ==============================================================================
resource "azurerm_role_assignment" "monitoring_reader" {
  count                = var.monitoring_scope != null ? 1 : 0
  scope                = var.monitoring_scope
  role_definition_name = "Monitoring Reader"
  principal_id         = azurerm_dashboard_grafana.this.identity[0].principal_id

  lifecycle {
    ignore_changes = [principal_id]
  }
}
