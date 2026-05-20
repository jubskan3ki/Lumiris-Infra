# Switch to the R2 backend below once `module.storage.r2_buckets.tfstate` exists, then `terraform init -migrate-state`.
#   terraform {
#     backend "s3" {
#       bucket                      = "lumiris-tfstate"
#       key                         = "prod.tfstate"
#       region                      = "auto"
#       endpoints                   = { s3 = "https://<account>.r2.cloudflarestorage.com" }
#       skip_credentials_validation = true
#       skip_metadata_api_check     = true
#       skip_region_validation      = true
#       skip_requesting_account_id  = true
#       use_path_style              = true
#     }
#   }
terraform {
  backend "local" {}
}
