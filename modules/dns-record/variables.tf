variable "zone_name" {
  type        = string
  description = "DNS zone name where all records will be created."
}

variable "resource_group_name" {
  type        = string
  description = "Resource group containing the target DNS zone."
}

variable "default_ttl" {
  type        = number
  description = "Default TTL in seconds applied to records that do not specify their own TTL."
  default     = 300
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to all DNS record resources."
  default     = {}
}

variable "a_records" {
  type = list(object({
    name    = string           # Record name (e.g. "api" or "@" for zone apex)
    records = list(string)     # List of IPv4 addresses
    ttl     = optional(number) # Per-record TTL override; defaults to var.default_ttl
  }))
  description = "A records to create (name → IPv4 address list)."
  default     = []
}

variable "cname_records" {
  type = list(object({
    name   = string           # Record name (e.g. "www")
    record = string           # Target domain name
    ttl    = optional(number) # Per-record TTL override
  }))
  description = "CNAME records to create (name → target domain)."
  default     = []
}

variable "txt_records" {
  type = list(object({
    name    = string           # Record name (e.g. "@" or "_dmarc")
    records = list(string)     # List of TXT values
    ttl     = optional(number) # Per-record TTL override
  }))
  description = "TXT records to create (for verification, SPF, DMARC, etc.)."
  default     = []
}
