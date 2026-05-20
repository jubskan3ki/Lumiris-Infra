variable "project_name" {
  description = "Infisical project slug (e.g. lumiris)."
  type        = string
}

variable "envs" {
  description = "Infisical environments to create (dev, staging, prod)."
  type        = list(string)
  default     = ["dev", "staging", "prod"]
}

variable "infisical_api_url" {
  description = "Infisical API URL — https://eu.infisical.com for EU tenant."
  type        = string
  default     = "https://eu.infisical.com"
}

variable "folders" {
  description = "Top-level folders to create per env."
  type        = list(string)
  default     = ["backend", "admin", "site", "client", "mobile", "infra"]
}
