module "dns" {
  source = "./modules/dns"

  domain         = var.domain
  account_id     = var.cloudflare_account_id
  vps_ip         = var.vps_ip
  vps_ipv6       = var.vps_ipv6
  app_subdomains = local.app_subdomains
}

module "storage" {
  source = "./modules/storage"

  account_id  = var.cloudflare_account_id
  buckets     = local.r2_buckets
  custom_cdn  = "cdn.${var.domain}"
  cdn_enabled = true
}

module "secrets" {
  source = "./modules/secrets"

  project_name      = local.project
  envs              = ["dev", "staging", "prod"]
  infisical_api_url = var.infisical_api_url
}

module "monitoring" {
  source = "./modules/monitoring"

  stack_name = local.project
  region     = "prod-eu-west-0"
  api_key    = var.grafana_cloud_api_key
  contact    = var.contact_email
}
