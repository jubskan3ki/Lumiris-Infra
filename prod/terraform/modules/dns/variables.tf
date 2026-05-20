variable "domain" {
  description = "Apex domain — e.g. lumiris.eu."
  type        = string
}

variable "account_id" {
  description = "Cloudflare account ID hosting the zone."
  type        = string
}

variable "vps_ip" {
  description = "Public IPv4 of the VPS — all A records point here."
  type        = string
}

variable "vps_ipv6" {
  description = "Public IPv6 of the VPS (optional)."
  type        = string
  default     = ""
}

variable "app_subdomains" {
  description = "Subdomains routed by Traefik (e.g. api, admin, client, mobile)."
  type        = list(string)
}

variable "proxied" {
  description = "Whether to enable Cloudflare proxy on app records (orange cloud)."
  type        = bool
  default     = true
}
