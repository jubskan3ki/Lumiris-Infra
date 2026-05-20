# prod/

**Inert until a VPS is provisioned.** Everything here is syntactically valid and
lint-clean, but nothing runs by default: no Terraform `apply`, no Ansible play,
no compose `up`, no workflow that pushes to GHCR or to a host.

When the VPS is delivered, follow [`../docs/MIGRATION-TO-PROD.md`](../docs/MIGRATION-TO-PROD.md)
step by step. The order is:

1. Sign up to the external accounts listed in [`../docs/ONBOARDING-PROD.md`](../docs/ONBOARDING-PROD.md).
2. Fill `secrets/prod.env.sops.yaml` and encrypt it with `sops`.
3. Fill `prod/terraform/envs/prod/terraform.tfvars` and run `make prod-plan`.
4. Fill `prod/ansible/inventories/prod/hosts.yml` and run `make prod-bootstrap`.

## Layout

```text
prod/
├── docker-compose.prod.yml         # 5 apps from GHCR + traefik + otel-collector + node-exporter + cadvisor
├── .env.prod.example               # template — real values come from Infisical at runtime
├── terraform/                      # Cloudflare DNS + R2 + Infisical project + Grafana Cloud stack
│   ├── versions.tf / providers.tf / variables.tf / outputs.tf / locals.tf / backend.tf
│   ├── envs/prod/                  # one stack per env
│   └── modules/{dns,storage,secrets,monitoring}/
├── ansible/                        # roles inspired by Portfolio (common, docker, infisical, traefik, monitoring, app)
│   ├── ansible.cfg / requirements.yml
│   ├── inventories/prod/           # hosts.yml.example + group_vars
│   ├── playbooks/                  # site, bootstrap, deploy, backup, rotate-secrets
│   └── roles/
├── traefik-prod/                   # static + dynamic configs (ACME Let's Encrypt)
└── monitoring-prod/                # OTel collector config forwarding to Grafana Cloud
```

## Why "inert" and not "removed"?

So that the day the VPS arrives, the work is **configuration**, not
**implementation**. `make prod-check` already validates the scaffolding today
(Terraform fmt + validate, ansible-lint, yamllint, shellcheck) — it just refuses
to do anything with side effects until the secrets and inventory are filled in.

## Activation gate

`scripts/prod-bootstrap.sh` is the orchestrator. It refuses to run until every
one of these files exists with real (non-placeholder) values:

- `secrets/prod.env.sops.yaml` (encrypted, with `sops` magic header)
- `$SOPS_AGE_KEY_FILE` pointing to a readable age private key
- `prod/ansible/inventories/prod/hosts.yml` (not `.example`)
- `prod/terraform/envs/prod/terraform.tfvars` (not `.example`)

If any check fails, it prints which step in `MIGRATION-TO-PROD.md` to read.
