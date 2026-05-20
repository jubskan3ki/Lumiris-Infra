variable "stack_name" {
  description = "Grafana Cloud stack slug (e.g. lumiris)."
  type        = string
}

variable "region" {
  description = "Grafana Cloud region — prod-eu-west-0 for EU."
  type        = string
  default     = "prod-eu-west-0"
}

variable "api_key" {
  description = "Grafana Cloud API key used to provision the stack."
  type        = string
  sensitive   = true
  default     = ""
}

variable "contact" {
  description = "Email surfaced on the stack — used for incident notifications."
  type        = string
}
