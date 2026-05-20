output "project_id" {
  description = "Infisical project ID (placeholder until the provider is wired)."
  value       = random_uuid.project_id_placeholder.result
}

output "api_url" {
  description = "Infisical API URL."
  value       = var.infisical_api_url
}

output "ci_client_id" {
  description = "Universal-auth client_id for the CI identity."
  value       = random_password.ci_client_id_placeholder.result
  sensitive   = true
}

output "ci_client_secret" {
  description = "Universal-auth client_secret for the CI identity."
  value       = random_password.ci_client_secret_placeholder.result
  sensitive   = true
}

output "vps_client_id" {
  description = "Universal-auth client_id for the VPS runtime identity."
  value       = random_password.vps_client_id_placeholder.result
  sensitive   = true
}

output "vps_client_secret" {
  description = "Universal-auth client_secret for the VPS runtime identity."
  value       = random_password.vps_client_secret_placeholder.result
  sensitive   = true
}
