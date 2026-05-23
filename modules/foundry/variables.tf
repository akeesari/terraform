variable "name" {
  type        = string
  description = "Project name used in resource naming (lowercase alphanumeric only, e.g. 'myproject')."
  validation {
    condition     = can(regex("^[a-z0-9]+$", var.name))
    error_message = "name must be lowercase alphanumeric characters only."
  }
}

variable "resource_group_name" {
  type        = string
  description = "Resource group that will contain all AI Foundry resources."
}

variable "location" {
  type        = string
  description = "Azure region for all resources (e.g. eastus, westus2)."
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to all resources in this module."
  default     = {}
}

variable "environment" {
  type        = string
  description = "Environment suffix used in resource naming (dev, test, prod)."
  default     = "dev"
  validation {
    condition     = contains(["dev", "test", "prod"], var.environment)
    error_message = "environment must be dev, test, or prod."
  }
}

variable "model_location" {
  type        = string
  description = "Azure region for model deployments (can differ from location for availability). Defaults to var.location."
  default     = null
}

# ---------------------------------------------------------------------------
# AI Foundry Configuration
# ---------------------------------------------------------------------------

variable "ai_foundry_sku" {
  type        = string
  description = "AI Foundry account SKU. Only S0 (Standard) is supported."
  default     = "S0"
  validation {
    condition     = contains(["S0"], var.ai_foundry_sku)
    error_message = "ai_foundry_sku must be S0."
  }
}

variable "enable_managed_identity" {
  type        = bool
  description = "Enable system-assigned managed identity on the AI Foundry account and project."
  default     = true
}

variable "disable_local_auth" {
  type        = bool
  description = "Disable local/key-based authentication on AI Foundry and AI Search (Entra ID only). Set false only to preserve existing deployments that were provisioned with local auth enabled."
  default     = true
}

variable "project_friendly_name" {
  type        = string
  description = "Human-readable display name for the AI Foundry project in the portal."
  default     = null
}

variable "project_description" {
  type        = string
  description = "Description of the AI Foundry project."
  default     = null
}

variable "enable_data_collection" {
  type        = bool
  description = "Enable data collection for the AI Foundry project."
  default     = true
}

variable "enable_telemetry" {
  type        = bool
  description = "Enable telemetry for the AI Foundry project."
  default     = true
}

# ---------------------------------------------------------------------------
# Storage Account
# ---------------------------------------------------------------------------

variable "create_storage_account" {
  type        = bool
  description = "Create a dedicated storage account for AI Foundry."
  default     = true
}

# ---------------------------------------------------------------------------
# AI Search
# ---------------------------------------------------------------------------

variable "create_ai_search" {
  type        = bool
  description = "Create an Azure AI Search service for vector embeddings."
  default     = true
}

variable "search_sku" {
  type        = string
  description = "AI Search service SKU (basic, standard, standard2, standard3)."
  default     = "basic"
  validation {
    condition     = contains(["basic", "standard", "standard2", "standard3"], var.search_sku)
    error_message = "search_sku must be basic, standard, standard2, or standard3."
  }
}

variable "search_replica_count" {
  type        = number
  description = "Number of search replicas (1–12)."
  default     = 1
  validation {
    condition     = var.search_replica_count >= 1 && var.search_replica_count <= 12
    error_message = "search_replica_count must be between 1 and 12."
  }
}

variable "search_partition_count" {
  type        = number
  description = "Number of search partitions (1–12)."
  default     = 1
  validation {
    condition     = var.search_partition_count >= 1 && var.search_partition_count <= 12
    error_message = "search_partition_count must be between 1 and 12."
  }
}

variable "enable_semantic_search" {
  type        = bool
  description = "Enable semantic search (standard tier). Incurs additional cost."
  default     = false
}

# ---------------------------------------------------------------------------
# Network / Security
# ---------------------------------------------------------------------------

variable "enable_private_endpoints" {
  type        = bool
  description = "Restrict network access; enable private endpoints (use standalone private_endpoint module at stack level)."
  default     = false
}

variable "allowed_ip_ranges" {
  type        = list(string)
  description = "IP ranges allowed through the network ACL when public access is enabled."
  default     = []
}

# ---------------------------------------------------------------------------
# GPT-4o
# ---------------------------------------------------------------------------

variable "deploy_gpt4o" {
  type        = bool
  description = "Deploy GPT-4o model."
  default     = true
}

variable "gpt4o_capacity" {
  type        = number
  description = "GPT-4o throughput capacity (tokens per minute × 1000, e.g. 10 = 10k TPM)."
  default     = 10
  validation {
    condition     = var.gpt4o_capacity >= 1 && var.gpt4o_capacity <= 1000
    error_message = "gpt4o_capacity must be between 1 and 1000."
  }
}

variable "gpt4o_model_name" {
  type        = string
  description = "Underlying GPT-4o model name (e.g. gpt-4o, gpt-5.1). Must match what is deployed in Azure."
  default     = "gpt-4o"
}

variable "gpt4o_version" {
  type        = string
  description = "GPT-4o model version."
  default     = "2024-05-13"
}

variable "gpt4o_sku" {
  type        = string
  description = "Deployment SKU for GPT-4o (Standard, GlobalStandard, DataZoneStandard)."
  default     = "Standard"
}

# ---------------------------------------------------------------------------
# GPT-4o-mini
# ---------------------------------------------------------------------------

variable "deploy_gpt4o_mini" {
  type        = bool
  description = "Deploy GPT-4o-mini model."
  default     = true
}

variable "gpt4o_mini_capacity" {
  type        = number
  description = "GPT-4o-mini throughput capacity (TPM × 1000)."
  default     = 10
  validation {
    condition     = var.gpt4o_mini_capacity >= 1 && var.gpt4o_mini_capacity <= 1000
    error_message = "gpt4o_mini_capacity must be between 1 and 1000."
  }
}

variable "gpt4o_mini_model_name" {
  type        = string
  description = "Underlying GPT-4o-mini model name (e.g. gpt-4o-mini, gpt-4.1-mini). Must match what is deployed in Azure."
  default     = "gpt-4o-mini"
}

variable "gpt4o_mini_version" {
  type        = string
  description = "GPT-4o-mini model version."
  default     = "2024-07-18"
}

variable "gpt4o_mini_sku" {
  type        = string
  description = "Deployment SKU for GPT-4o-mini."
  default     = "Standard"
}

# ---------------------------------------------------------------------------
# GPT-5
# ---------------------------------------------------------------------------

variable "deploy_gpt5" {
  type        = bool
  description = "Deploy GPT-5 model."
  default     = false
}

variable "gpt5_capacity" {
  type        = number
  description = "GPT-5 throughput capacity (TPM × 1000)."
  default     = 10
}

variable "gpt5_version" {
  type        = string
  description = "GPT-5 model version."
  default     = "2024-12-01"
}

variable "gpt5_sku" {
  type        = string
  description = "Deployment SKU for GPT-5."
  default     = "Standard"
}

# ---------------------------------------------------------------------------
# Claude Sonnet
# ---------------------------------------------------------------------------

variable "deploy_claude_sonnet" {
  type        = bool
  description = "Deploy Claude Sonnet 4.5 model (requires Anthropic model provider metadata)."
  default     = false
}

variable "claude_sonnet_capacity" {
  type        = number
  description = "Claude Sonnet throughput capacity (TPM × 1000)."
  default     = 2000
}

variable "claude_sonnet_version" {
  type        = string
  description = "Claude Sonnet model version."
  default     = "20250929"
}

variable "claude_sonnet_sku" {
  type        = string
  description = "Deployment SKU for Claude Sonnet."
  default     = "GlobalStandard"
}

variable "anthropic_industry" {
  type        = string
  description = "Industry classification for Anthropic model provider metadata (required for Claude deployments)."
  default     = "Technology"
}

variable "anthropic_organization_name" {
  type        = string
  description = "Organization name for Anthropic model provider metadata (required for Claude deployments)."
  default     = null
}

variable "anthropic_country_code" {
  type        = string
  description = "ISO 3166-1 alpha-2 country code for Anthropic model provider metadata (e.g. US, GB)."
  default     = "US"
}
