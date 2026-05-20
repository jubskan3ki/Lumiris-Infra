# INERT until the Infisical/infisical provider is pinned in versions.tf.

# resource "infisical_project" "this" {
#   name = var.project_name
#   slug = var.project_name
# }
#
# resource "infisical_project_environment" "envs" {
#   for_each   = toset(var.envs)
#   project_id = infisical_project.this.id
#   name       = each.value
#   slug       = each.value
# }
#
# resource "infisical_secret_folder" "folders" {
#   for_each    = { for pair in setproduct(var.envs, var.folders) :
#                   "${pair[0]}-${pair[1]}" => { env = pair[0], folder = pair[1] } }
#   project_id  = infisical_project.this.id
#   environment = each.value.env
#   folder_path = "/${each.value.folder}"
# }
#
# resource "infisical_identity" "ci_github" {
#   name = "ci_github"
#   role = "admin"
# }
#
# resource "infisical_identity_universal_auth" "ci_github" {
#   identity_id = infisical_identity.ci_github.id
# }
#
# resource "infisical_identity" "vps_runtime" {
#   name = "vps_runtime"
#   role = "viewer"
# }
#
# resource "infisical_identity_universal_auth" "vps_runtime" {
#   identity_id = infisical_identity.vps_runtime.id
# }

# Placeholders so outputs stay well-typed while the module is inert.
resource "random_uuid" "project_id_placeholder" {}

resource "random_password" "ci_client_id_placeholder" {
  length  = 36
  special = false
}

resource "random_password" "ci_client_secret_placeholder" {
  length  = 64
  special = false
}

resource "random_password" "vps_client_id_placeholder" {
  length  = 36
  special = false
}

resource "random_password" "vps_client_secret_placeholder" {
  length  = 64
  special = false
}
