resource "cloudflare_r2_bucket" "buckets" {
  for_each = var.buckets

  account_id = var.account_id
  name       = "lumiris-${each.key}"
  location   = var.location
}

# Backup passphrase: copy the output into Infisical, never commit it.
resource "random_password" "backup_passphrase" {
  length           = 64
  special          = true
  override_special = "!@#$%^&*()-_=+[]{}<>?,."
}

# Placeholders until `cloudflare_api_token` scope strings are finalised.
resource "random_password" "r2_access_key_placeholder" {
  length           = 32
  special          = false
  override_special = ""
}

resource "random_password" "r2_secret_key_placeholder" {
  length           = 64
  special          = false
  override_special = ""
}
