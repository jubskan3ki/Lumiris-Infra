locals {
  project = "lumiris"
  env     = "prod"

  app_subdomains = [
    "api",
    "admin",
    "client",
    "mobile",
  ]

  r2_buckets = {
    uploads = { public = false, description = "User uploads (audit reports, evidence)." }
    assets  = { public = true, description = "Static assets served via cdn.${var.domain}." }
    backups = { public = false, description = "Postgres dumps, encrypted with backup_passphrase." }
    tfstate = { public = false, description = "Terraform remote state, encryption at rest." }
  }
}
