# INERT until the grafana/grafana provider is pinned in versions.tf and provider aliases configured.

# resource "grafana_cloud_stack" "this" {
#   provider     = grafana.cloud
#   name         = var.stack_name
#   slug         = var.stack_name
#   region_slug  = var.region
#   description  = "Lumiris production stack"
# }
#
# resource "grafana_cloud_access_policy" "all_in_one" {
#   provider    = grafana.cloud
#   name        = "${var.stack_name}-otel-collector"
#   display_name = "OTel collector push (metrics/logs/traces)"
#   region      = var.region
#   scopes      = ["metrics:write", "logs:write", "traces:write"]
# }
#
# resource "grafana_cloud_access_policy_token" "all_in_one" {
#   provider         = grafana.cloud
#   region           = var.region
#   access_policy_id = grafana_cloud_access_policy.all_in_one.policy_id
#   name             = "${var.stack_name}-otel-token"
# }

# Placeholder so `terraform validate` succeeds while the module is inert.
resource "random_password" "all_in_one_token_placeholder" {
  length  = 64
  special = false
}
