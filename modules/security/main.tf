# ==============================================================================
# Microsoft Defender for Cloud
# Set enable_security = true to activate Defender plans and security contact.
# ==============================================================================

# CSPM Free — baseline posture management
resource "azurerm_security_center_subscription_pricing" "cspm" {
  count         = var.enable_security ? 1 : 0
  tier          = "Free"
  resource_type = "CloudPosture"
}

# Defender for Servers
resource "azurerm_security_center_subscription_pricing" "servers" {
  count         = var.enable_security ? 1 : 0
  tier          = var.enable_defender_for_servers ? "Standard" : "Free"
  resource_type = "VirtualMachines"
  subplan       = var.enable_defender_for_servers ? var.defender_servers_subplan : null
}

# Defender for Containers
resource "azurerm_security_center_subscription_pricing" "containers" {
  count         = var.enable_security ? 1 : 0
  tier          = var.enable_defender_for_containers ? "Standard" : "Free"
  resource_type = "Containers"
}

# Defender for Azure SQL
resource "azurerm_security_center_subscription_pricing" "sql" {
  count         = var.enable_security ? 1 : 0
  tier          = var.enable_defender_for_databases ? "Standard" : "Free"
  resource_type = "SqlServers"
}

# Defender for OSS Databases
resource "azurerm_security_center_subscription_pricing" "oss_db" {
  count         = var.enable_security ? 1 : 0
  tier          = var.enable_defender_for_databases ? "Standard" : "Free"
  resource_type = "OpenSourceRelationalDatabases"
}

# Defender for Key Vault
resource "azurerm_security_center_subscription_pricing" "keyvault" {
  count         = var.enable_security ? 1 : 0
  tier          = var.enable_defender_for_key_vault ? "Standard" : "Free"
  resource_type = "KeyVaults"
  subplan       = var.enable_defender_for_key_vault ? "PerKeyVault" : null
}

# Defender for ARM
resource "azurerm_security_center_subscription_pricing" "arm" {
  count         = var.enable_security ? 1 : 0
  tier          = "Standard"
  resource_type = "Arm"
  subplan       = "PerSubscription"
}

# Defender for Storage — detect malicious uploads and anomalous access
resource "azurerm_security_center_subscription_pricing" "storage" {
  count         = var.enable_security ? 1 : 0
  tier          = "Standard"
  resource_type = "StorageAccounts"
  subplan       = "DefenderForStorageV2"
}

# Defender for App Service
resource "azurerm_security_center_subscription_pricing" "app_service" {
  count         = var.enable_security ? 1 : 0
  tier          = var.enable_defender_for_app_service ? "Standard" : "Free"
  resource_type = "AppServices"
}

# Security contact
resource "azurerm_security_center_contact" "default" {
  count               = var.enable_security ? 1 : 0
  name                = "default"
  email               = var.security_contact_email
  alert_notifications = true
  alerts_to_admins    = true
}
