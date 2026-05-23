data "azurerm_client_config" "current" {}

# ---------------------------------------------------------------------------
# Storage Account for AI Foundry
# ---------------------------------------------------------------------------

resource "azurerm_storage_account" "foundry_storage" {
  count = var.create_storage_account ? 1 : 0

  name                            = "staif${var.name}${var.environment}"
  resource_group_name             = var.resource_group_name
  location                        = var.location
  account_kind                    = "StorageV2"
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  shared_access_key_enabled       = true # Required for AI Foundry provisioning
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  https_traffic_only_enabled      = true

  network_rules {
    default_action = var.enable_private_endpoints ? "Deny" : "Allow"
    bypass         = ["AzureServices"]
    ip_rules       = var.allowed_ip_ranges
  }

  tags = merge(var.tags, { Purpose = "AI Foundry Storage" })

  lifecycle {
    precondition {
      condition     = length("staif${var.name}${var.environment}") <= 24
      error_message = "Computed storage account name 'staif${var.name}${var.environment}' exceeds 24 characters. Shorten var.name or var.environment."
    }
    ignore_changes = [tags["CreatedDate"], tags["LastModified"], network_rules]
  }
}

# ---------------------------------------------------------------------------
# AI Search Service (optional)
# ---------------------------------------------------------------------------

resource "azapi_resource" "ai_search" {
  count = var.create_ai_search ? 1 : 0

  type      = "Microsoft.Search/searchServices@2024-06-01-preview"
  name      = "srch-${var.name}-${var.environment}"
  parent_id = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${var.resource_group_name}"
  location  = var.location

  body = {
    sku      = { name = var.search_sku }
    identity = { type = "SystemAssigned" }
    properties = {
      replicaCount     = var.search_replica_count
      partitionCount   = var.search_partition_count
      hostingMode      = "default"
      semanticSearch   = var.enable_semantic_search ? "standard" : "disabled"
      disableLocalAuth = var.disable_local_auth
      authOptions = {
        aadOrApiKey = { aadAuthFailureMode = "http401WithBearerChallenge" }
      }
      publicNetworkAccess = var.enable_private_endpoints ? "Disabled" : "Enabled"
      networkRuleSet = {
        bypass  = "None"
        ipRules = var.enable_private_endpoints ? [] : [for ip in var.allowed_ip_ranges : { value = ip }]
      }
    }
  }

  tags = merge(var.tags, { Purpose = "AI Search" })

  lifecycle {
    ignore_changes = [tags]
  }
}

# ---------------------------------------------------------------------------
# AI Foundry Account
# ---------------------------------------------------------------------------

resource "azapi_resource" "ai_foundry" {
  type      = "Microsoft.CognitiveServices/accounts@2025-04-01-preview"
  name      = "aif-${var.name}-${var.environment}"
  parent_id = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${var.resource_group_name}"
  location  = var.model_location != null ? var.model_location : var.location

  schema_validation_enabled = false

  body = {
    kind     = "AIServices"
    sku      = { name = var.ai_foundry_sku }
    identity = { type = var.enable_managed_identity ? "SystemAssigned" : "None" }
    properties = {
      apiProperties          = {}
      disableLocalAuth       = var.disable_local_auth
      allowProjectManagement = true
      customSubDomainName    = "aif-${var.name}-${var.environment}"
      publicNetworkAccess    = var.enable_private_endpoints ? "Disabled" : "Enabled"
      networkAcls = {
        defaultAction       = var.enable_private_endpoints ? "Deny" : "Allow"
        ipRules             = var.allowed_ip_ranges
        virtualNetworkRules = []
      }
    }
  }

  tags = merge(var.tags, { Purpose = "AI Foundry Hub" })

  response_export_values = ["identity.principalId", "properties.endpoint"]

  lifecycle { ignore_changes = [tags] }
}

# ---------------------------------------------------------------------------
# AI Foundry Project
# ---------------------------------------------------------------------------

resource "azapi_resource" "ai_foundry_project" {
  type      = "Microsoft.CognitiveServices/accounts/projects@2025-04-01-preview"
  name      = "aifp-${var.name}-${var.environment}"
  parent_id = azapi_resource.ai_foundry.id
  location  = var.model_location != null ? var.model_location : var.location

  schema_validation_enabled = false

  body = {
    kind     = "AIServices"
    identity = { type = var.enable_managed_identity ? "SystemAssigned" : "None" }
    properties = {
      description = coalesce(var.project_description, "AI Foundry project for ${var.name}")
      displayName = coalesce(var.project_friendly_name, "${var.name} Project")
      projectSettings = {
        enableDataCollection = var.enable_data_collection
        enableTelemetry      = var.enable_telemetry
      }
    }
  }

  tags = merge(var.tags, { Purpose = "AI Foundry Project" })

  response_export_values = ["identity.principalId", "properties.internalId"]

  lifecycle { ignore_changes = [tags] }
}

# Allow the project managed identity to propagate before creating connections
resource "time_sleep" "wait_project_identity" {
  depends_on      = [azapi_resource.ai_foundry_project]
  create_duration = "10s"
}

# ---------------------------------------------------------------------------
# Model Deployments
# ---------------------------------------------------------------------------

locals {
  model_definitions = {
    gpt-4o = {
      enabled  = var.deploy_gpt4o
      format   = "OpenAI"
      name     = var.gpt4o_model_name
      version  = var.gpt4o_version
      sku      = var.gpt4o_sku
      capacity = var.gpt4o_capacity
    }
    gpt-4o-mini = {
      enabled  = var.deploy_gpt4o_mini
      format   = "OpenAI"
      name     = var.gpt4o_mini_model_name
      version  = var.gpt4o_mini_version
      sku      = var.gpt4o_mini_sku
      capacity = var.gpt4o_mini_capacity
    }
    gpt-5 = {
      enabled  = var.deploy_gpt5
      format   = "OpenAI"
      name     = "gpt-5"
      version  = var.gpt5_version
      sku      = var.gpt5_sku
      capacity = var.gpt5_capacity
    }
    claude-sonnet = {
      enabled  = var.deploy_claude_sonnet
      format   = "Anthropic"
      name     = "claude-sonnet-4-5"
      version  = var.claude_sonnet_version
      sku      = var.claude_sonnet_sku
      capacity = var.claude_sonnet_capacity
    }
  }

  openai_models = {
    for k, m in local.model_definitions : k => m
    if m.enabled && m.format == "OpenAI"
  }

  anthropic_models = {
    for k, m in local.model_definitions : k => m
    if m.enabled && m.format == "Anthropic"
  }
}

resource "azurerm_cognitive_deployment" "openai_models" {
  for_each = local.openai_models

  name                   = each.key
  cognitive_account_id   = azapi_resource.ai_foundry.id
  version_upgrade_option = "OnceNewDefaultVersionAvailable"

  model {
    format  = each.value.format
    name    = each.value.name
    version = each.value.version
  }

  sku {
    name     = each.value.sku
    capacity = each.value.capacity
  }

  depends_on = [azapi_resource.ai_foundry, azapi_resource.ai_foundry_project]
}

resource "azapi_resource" "anthropic_models" {
  for_each = local.anthropic_models

  type                      = "Microsoft.CognitiveServices/accounts/deployments@2025-04-01-preview"
  schema_validation_enabled = false
  name                      = each.key
  parent_id                 = azapi_resource.ai_foundry.id

  body = {
    properties = {
      model = {
        format  = each.value.format
        name    = each.value.name
        version = each.value.version
      }
      versionUpgradeOption = "OnceNewDefaultVersionAvailable"
      modelProviderData = {
        industry         = var.anthropic_industry
        organizationName = var.anthropic_organization_name
        countryCode      = var.anthropic_country_code
      }
    }
    sku = {
      name     = each.value.sku
      capacity = each.value.capacity
    }
  }

  depends_on = [azapi_resource.ai_foundry, azapi_resource.ai_foundry_project]
}

# ---------------------------------------------------------------------------
# Project Connections
# ---------------------------------------------------------------------------

resource "azapi_resource" "conn_storage" {
  count = var.create_storage_account ? 1 : 0

  type                      = "Microsoft.CognitiveServices/accounts/projects/connections@2025-04-01-preview"
  schema_validation_enabled = false
  name                      = azurerm_storage_account.foundry_storage[0].name
  parent_id                 = azapi_resource.ai_foundry_project.id

  body = {
    name = azurerm_storage_account.foundry_storage[0].name
    properties = {
      category                    = "AzureStorageAccount"
      target                      = azurerm_storage_account.foundry_storage[0].primary_blob_endpoint
      authType                    = "AAD"
      useWorkspaceManagedIdentity = false
      isSharedToAll               = false
      sharedUserList              = []
      peRequirement               = "NotRequired"
      peStatus                    = "NotApplicable"
      metadata = {
        ApiType    = "Azure"
        ResourceId = azurerm_storage_account.foundry_storage[0].id
        location   = var.location
      }
    }
  }

  depends_on = [time_sleep.wait_project_identity]
}

resource "azapi_resource" "conn_search" {
  count = var.create_ai_search ? 1 : 0

  type                      = "Microsoft.CognitiveServices/accounts/projects/connections@2025-04-01-preview"
  schema_validation_enabled = false
  name                      = azapi_resource.ai_search[0].name
  parent_id                 = azapi_resource.ai_foundry_project.id

  body = {
    name = azapi_resource.ai_search[0].name
    properties = {
      category                    = "CognitiveSearch"
      target                      = "https://${azapi_resource.ai_search[0].name}.search.windows.net/"
      authType                    = "AAD"
      useWorkspaceManagedIdentity = false
      isSharedToAll               = false
      sharedUserList              = []
      peRequirement               = "NotRequired"
      peStatus                    = "NotApplicable"
      metadata = {
        type                 = "azure_ai_search"
        ApiType              = "Azure"
        ResourceId           = azapi_resource.ai_search[0].id
        ApiVersion           = "2024-05-01-preview"
        DeploymentApiVersion = "2023-11-01"
        location             = var.location
      }
    }
  }

  depends_on = [time_sleep.wait_project_identity]
}

# ---------------------------------------------------------------------------
# Role Assignments — AI Foundry managed identities → Search & Storage
# ---------------------------------------------------------------------------

# AI Foundry account MSI: Reader on the resource group
resource "azurerm_role_assignment" "ai_foundry_resource_group_reader" {
  count                = var.enable_managed_identity ? 1 : 0
  scope                = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${var.resource_group_name}"
  role_definition_name = "Reader"
  principal_id         = azapi_resource.ai_foundry.output.identity.principalId

  depends_on = [azapi_resource.ai_foundry]
}

# AI Foundry account MSI: Search Service Contributor on AI Search
resource "azurerm_role_assignment" "search_service_contributor_ai_foundry_account" {
  count                = var.enable_managed_identity && var.create_ai_search ? 1 : 0
  scope                = azapi_resource.ai_search[0].id
  role_definition_name = "Search Service Contributor"
  principal_id         = azapi_resource.ai_foundry.output.identity.principalId

  depends_on = [azapi_resource.ai_foundry, azapi_resource.ai_search]
}

# AI Foundry account MSI: Storage Blob Data Contributor on Foundry storage
resource "azurerm_role_assignment" "storage_blob_data_contributor_ai_foundry_account" {
  count                = var.enable_managed_identity && var.create_storage_account ? 1 : 0
  scope                = azurerm_storage_account.foundry_storage[0].id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azapi_resource.ai_foundry.output.identity.principalId

  depends_on = [azapi_resource.ai_foundry, azurerm_storage_account.foundry_storage]
}

# AI Foundry project MSI: Search Service Contributor on AI Search
resource "azurerm_role_assignment" "search_service_contributor_ai_foundry_project" {
  count                = var.enable_managed_identity && var.create_ai_search ? 1 : 0
  scope                = azapi_resource.ai_search[0].id
  role_definition_name = "Search Service Contributor"
  principal_id         = azapi_resource.ai_foundry_project.output.identity.principalId

  depends_on = [azapi_resource.ai_foundry_project, azapi_resource.ai_search]
}

# AI Foundry project MSI: Search Index Data Contributor on AI Search
resource "azurerm_role_assignment" "search_index_data_contributor_ai_foundry_project" {
  count                = var.enable_managed_identity && var.create_ai_search ? 1 : 0
  scope                = azapi_resource.ai_search[0].id
  role_definition_name = "Search Index Data Contributor"
  principal_id         = azapi_resource.ai_foundry_project.output.identity.principalId

  depends_on = [azapi_resource.ai_foundry_project, azapi_resource.ai_search]
}

# AI Foundry project MSI: Storage Blob Data Contributor on Foundry storage
resource "azurerm_role_assignment" "storage_blob_data_contributor_ai_foundry_project" {
  count                = var.enable_managed_identity && var.create_storage_account ? 1 : 0
  scope                = azurerm_storage_account.foundry_storage[0].id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azapi_resource.ai_foundry_project.output.identity.principalId

  depends_on = [azapi_resource.ai_foundry_project, azurerm_storage_account.foundry_storage]
}

# AI Foundry project MSI: Storage Blob Data Owner on Foundry storage
resource "azurerm_role_assignment" "storage_blob_data_owner_ai_foundry_project" {
  count                = var.enable_managed_identity && var.create_storage_account ? 1 : 0
  scope                = azurerm_storage_account.foundry_storage[0].id
  role_definition_name = "Storage Blob Data Owner"
  principal_id         = azapi_resource.ai_foundry_project.output.identity.principalId

  depends_on = [azapi_resource.ai_foundry_project, azurerm_storage_account.foundry_storage]
}
