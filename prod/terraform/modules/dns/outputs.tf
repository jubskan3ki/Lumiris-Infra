output "zone_id" {
  description = "Cloudflare zone ID."
  value       = cloudflare_zone.this.id
}

output "nameservers" {
  description = "Authoritative nameservers — set these at the domain registrar."
  value       = cloudflare_zone.this.name_servers
}

output "records" {
  description = "Map of subdomain → record FQDN."
  value = merge(
    {
      "@"   = cloudflare_record.apex.hostname
      "www" = cloudflare_record.www.hostname
      "cdn" = cloudflare_record.cdn.hostname
    },
    { for k, r in cloudflare_record.apps : k => r.hostname },
  )
}
