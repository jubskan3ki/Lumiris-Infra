# Terraform modules

Four modules covering everything that lives *outside* the VPS. The VPS itself
is provisioned manually (school-provided IP) and configured by Ansible — there
is no `compute/` module.

| Module        | Provider(s)     | What it creates                                                 |
| ------------- | --------------- | --------------------------------------------------------------- |
| `dns/`        | Cloudflare      | Zone `lumiris.eu`, A records, security headers, CDN CNAME       |
| `storage/`    | Cloudflare R2   | 4 buckets (uploads, assets, backups, tfstate) + scoped token    |
| `secrets/`    | Infisical (TBD) | Project + folders + identities for CI and the VPS runtime       |
| `monitoring/` | Grafana Cloud   | Stack + Prometheus/Loki/Tempo push URLs + all-in-one token      |

## Inert by default

`secrets/` and `monitoring/` are scaffold-only — their resource blocks are
commented out because the Infisical and Grafana Cloud Terraform providers are
not yet pinned in `versions.tf`. Their outputs return placeholder strings so
that `terraform validate` passes today; flip them on at activation time by:

1. Adding the provider to `../versions.tf` (`required_providers`)
2. Configuring it in `../providers.tf`
3. Uncommenting the resource blocks in `secrets/main.tf` / `monitoring/main.tf`
4. Replacing the placeholder outputs with the real resource attributes

## Why not a `compute/` module?

The VPS is delivered ready-to-SSH by the school. Ansible handles configuration
from there. Reintroducing a `compute/` module makes sense only if/when we
self-provision (Hetzner Cloud, OVH, Scaleway, …).
