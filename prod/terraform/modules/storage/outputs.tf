output "endpoint" {
  description = "S3-compatible endpoint for the R2 account."
  value       = "https://${var.account_id}.r2.cloudflarestorage.com"
}

output "buckets" {
  description = "Map of bucket name → bucket id."
  value       = { for k, b in cloudflare_r2_bucket.buckets : k => b.id }
}

output "access_key_id" {
  description = "R2 access key id used by the application. Push to Infisical and delete from state output once consumed."
  value       = random_password.r2_access_key_placeholder.result
  sensitive   = true
}

output "secret_access_key" {
  description = "R2 secret access key used by the application. Push to Infisical and delete from state output once consumed."
  value       = random_password.r2_secret_key_placeholder.result
  sensitive   = true
}

output "backup_passphrase" {
  description = "Passphrase used by the Postgres backup job to symmetric-encrypt dumps before R2 upload."
  value       = random_password.backup_passphrase.result
  sensitive   = true
}

output "cdn_domain" {
  description = "Custom CDN domain attached to the assets bucket (empty if cdn_enabled=false)."
  value       = var.cdn_enabled && var.custom_cdn != "" ? var.custom_cdn : ""
}
