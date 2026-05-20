variable "domain" {
  description = "Apex domain managed by Cloudflare (e.g. lumiris.eu)."
  type        = string
  default     = "lumiris.eu"
}

variable "contact_email" {
  description = "Email used for ACME / Cloudflare account contact and Grafana Cloud."
  type        = string
}

variable "cloudflare_api_token" {
  description = "Cloudflare API token with Zone:Edit + R2 + Workers permissions."
  type        = string
  sensitive   = true
}

variable "cloudflare_account_id" {
  description = "Cloudflare account ID hosting the zone and R2 buckets."
  type        = string
}

variable "vps_ip" {
  description = "Public IPv4 of the VPS — used for DNS A records."
  type        = string
}

variable "vps_ipv6" {
  description = "Public IPv6 of the VPS (optional)."
  type        = string
  default     = ""
}

variable "grafana_cloud_api_key" {
  description = "Grafana Cloud personal access token used to create the stack."
  type        = string
  sensitive   = true
  default     = ""
}

variable "infisical_api_url" {
  description = "Infisical API URL (https://eu.infisical.com for the EU tenant)."
  type        = string
  default     = "https://eu.infisical.com"
}

variable "tags" {
  description = "Common tags applied to taggable resources."
  type        = map(string)
  default = {
    project = "lumiris"
    env     = "prod"
    managed = "terraform"
  }
}
