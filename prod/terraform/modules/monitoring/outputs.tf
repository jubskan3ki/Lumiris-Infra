output "stack_slug" {
  description = "Grafana Cloud stack slug."
  value       = var.stack_name
}

output "region" {
  description = "Grafana Cloud region of the stack."
  value       = var.region
}

# Hardcoded until the grafana provider exposes `grafana_cloud_stack.*_endpoint` outputs.
output "prometheus_remote_write_url" {
  description = "Prometheus remote_write endpoint for OTel collector."
  value       = "https://prometheus-${var.region}.grafana.net/api/prom/push"
}

output "loki_push_url" {
  description = "Loki push endpoint for OTel collector / Promtail."
  value       = "https://logs-${var.region}.grafana.net/loki/api/v1/push"
}

output "tempo_otlp_url" {
  description = "Tempo OTLP/HTTP endpoint for OTel collector."
  value       = "https://tempo-${var.region}.grafana.net:443"
}

output "all_in_one_token" {
  description = "Access policy token allowed to push metrics, logs and traces."
  value       = random_password.all_in_one_token_placeholder.result
  sensitive   = true
}
