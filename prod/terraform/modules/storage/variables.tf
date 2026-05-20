variable "account_id" {
  description = "Cloudflare account ID hosting the R2 buckets."
  type        = string
}

variable "buckets" {
  description = "Buckets to create — key is bucket name, value carries metadata."
  type = map(object({
    public      = bool
    description = string
  }))
}

variable "location" {
  description = "R2 region — WEUR (Western Europe), ENAM (Eastern NA), …"
  type        = string
  default     = "WEUR"
}

variable "custom_cdn" {
  description = "Optional custom domain to attach to the assets bucket (e.g. cdn.lumiris.eu)."
  type        = string
  default     = ""
}

variable "cdn_enabled" {
  description = "Attach the custom_cdn to the assets bucket."
  type        = bool
  default     = false
}
