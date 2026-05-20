resource "cloudflare_zone" "this" {
  account_id = var.account_id
  zone       = var.domain
  plan       = "free"
  type       = "full"
}

resource "cloudflare_zone_settings_override" "this" {
  zone_id = cloudflare_zone.this.id

  settings {
    ssl                      = "full"
    always_use_https         = "on"
    automatic_https_rewrites = "on"
    min_tls_version          = "1.2"
    tls_1_3                  = "on"
    brotli                   = "on"
    http3                    = "on"
    zero_rtt                 = "on"
    opportunistic_encryption = "on"
    security_level           = "medium"
    browser_check            = "on"

    security_header {
      enabled            = true
      include_subdomains = true
      max_age            = 31536000
      nosniff            = true
      preload            = false
    }
  }
}

resource "cloudflare_record" "apex" {
  zone_id = cloudflare_zone.this.id
  name    = "@"
  content = var.vps_ip
  type    = "A"
  ttl     = 1
  proxied = var.proxied
  comment = "Lumiris site (managed by Terraform)"
}

resource "cloudflare_record" "www" {
  zone_id = cloudflare_zone.this.id
  name    = "www"
  content = var.vps_ip
  type    = "A"
  ttl     = 1
  proxied = var.proxied
  comment = "Lumiris site www alias (managed by Terraform)"
}

resource "cloudflare_record" "apps" {
  for_each = toset(var.app_subdomains)

  zone_id = cloudflare_zone.this.id
  name    = each.value
  content = var.vps_ip
  type    = "A"
  ttl     = 1
  proxied = var.proxied
  comment = "Lumiris ${each.value} subdomain (managed by Terraform)"
}

resource "cloudflare_record" "apex_v6" {
  count = var.vps_ipv6 == "" ? 0 : 1

  zone_id = cloudflare_zone.this.id
  name    = "@"
  content = var.vps_ipv6
  type    = "AAAA"
  ttl     = 1
  proxied = var.proxied
  comment = "Lumiris site IPv6 (managed by Terraform)"
}

# Placeholder target until R2 custom-domain wiring publishes the real public hostname.
resource "cloudflare_record" "cdn" {
  zone_id = cloudflare_zone.this.id
  name    = "cdn"
  content = "public-r2-endpoint.cloudflare.com"
  type    = "CNAME"
  ttl     = 1
  proxied = true
  comment = "R2 assets bucket CDN (managed by Terraform — content updated after R2 public access is enabled)"
}
