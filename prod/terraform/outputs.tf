output "dns_nameservers" {
  description = "Nameservers to set at the domain registrar after the zone is created."
  value       = module.dns.nameservers
}

output "dns_zone_id" {
  description = "Cloudflare zone ID."
  value       = module.dns.zone_id
}

output "r2_endpoint" {
  description = "Cloudflare R2 S3-compatible endpoint."
  value       = module.storage.endpoint
}

output "r2_buckets" {
  description = "Map of bucket name → bucket id."
  value       = module.storage.buckets
}

output "r2_access_key_id" {
  description = "R2 access key ID for the application identity (push to Infisical)."
  value       = module.storage.access_key_id
  sensitive   = true
}

output "r2_secret_access_key" {
  description = "R2 secret access key for the application identity (push to Infisical)."
  value       = module.storage.secret_access_key
  sensitive   = true
}

output "backup_passphrase" {
  description = "Random passphrase used by the Postgres backup job (push to Infisical)."
  value       = module.storage.backup_passphrase
  sensitive   = true
}

output "infisical_project_id" {
  description = "Infisical project ID used by GitHub Actions and the VPS runtime."
  value       = module.secrets.project_id
}

output "infisical_ci_client" {
  description = "Universal-auth client used by CI to push secrets."
  value = {
    client_id     = module.secrets.ci_client_id
    client_secret = module.secrets.ci_client_secret
  }
  sensitive = true
}

output "infisical_vps_client" {
  description = "Universal-auth client used by the VPS to read runtime secrets."
  value = {
    client_id     = module.secrets.vps_client_id
    client_secret = module.secrets.vps_client_secret
  }
  sensitive = true
}

output "grafana_cloud_endpoints" {
  description = "Grafana Cloud push URLs for OTel collector."
  value = {
    prometheus_remote_write = module.monitoring.prometheus_remote_write_url
    loki_push               = module.monitoring.loki_push_url
    tempo_otlp              = module.monitoring.tempo_otlp_url
  }
}

output "grafana_cloud_token" {
  description = "Grafana Cloud all-in-one access token (push to Infisical)."
  value       = module.monitoring.all_in_one_token
  sensitive   = true
}
