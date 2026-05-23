# =============================================================================
# pgAdmin Module Variables
# =============================================================================

variable "enabled" {
  description = "Enable pgAdmin deployment."
  type        = bool
  default     = false
}

variable "chart_version" {
  description = "pgAdmin4 Helm chart version."
  type        = string
  default     = "1.34.0"
}

variable "admin_email" {
  description = "pgAdmin admin login email."
  type        = string
  default     = ""
}

variable "admin_password" {
  description = "pgAdmin admin password. Source from Key Vault."
  type        = string
  sensitive   = true
  default     = ""
}

variable "ingress_hostname" {
  description = "Hostname for pgAdmin ingress (e.g. pgadmin.dev.example.com). Ingress is created when set."
  type        = string
  default     = ""
}

variable "cluster_issuer_name" {
  description = "cert-manager ClusterIssuer name for TLS certificates."
  type        = string
  default     = "letsencrypt-prod"
}

variable "ingress_class_name" {
  description = "Ingress class name for pgAdmin."
  type        = string
  default     = "nginx"
}

# PostgreSQL server pre-configuration
variable "project_name" {
  description = "Project name — used as the key for the pre-configured PostgreSQL server definition."
  type        = string
  default     = ""
}

variable "postgres_host" {
  description = "PostgreSQL server FQDN (e.g. pg-myapp-dev.postgres.database.azure.com)."
  type        = string
  default     = ""
}

variable "postgres_database" {
  description = "Default maintenance database name."
  type        = string
  default     = ""
}

variable "postgres_username" {
  description = "PostgreSQL login username shown in server definition."
  type        = string
  default     = "pgadmin"
}

variable "schedule_on_system_nodes" {
  description = "Pin the pgAdmin pod to the system node pool (nodeSelector kubernetes.azure.com/mode=system + CriticalAddonsOnly toleration). Set false to run on user nodes."
  type        = bool
  default     = true
}
