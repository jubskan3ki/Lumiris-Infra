# ansible/

Configuration management for the Lumiris production VPS. **Inert** until the
inventory in `inventories/prod/hosts.yml` is filled in (it ships only as
`hosts.yml.example`).

## Playbooks

| File                           | Purpose                                                 |
| ------------------------------ | ------------------------------------------------------- |
| `playbooks/site.yml`           | All roles, all hosts — full converge                    |
| `playbooks/bootstrap.yml`      | First-boot hardening (common → docker → infisical)      |
| `playbooks/deploy.yml`         | Pull GHCR images and roll the app stack (zero-downtime) |
| `playbooks/backup.yml`         | Trigger a Postgres dump → R2 (uses backup_passphrase)   |
| `playbooks/rotate-secrets.yml` | Re-pull Infisical secrets, restart impacted services    |

## Roles

| Role         | Inspired by Portfolio. Highlights                                                  |
| ------------ | ---------------------------------------------------------------------------------- |
| `common`     | tzdata, locales, swap, unattended-upgrades, journald, SSH hardening, UFW, fail2ban |
| `docker`     | Docker CE from upstream repo, compose plugin, buildx, daemon.json + log rotation   |
| `infisical`  | Install CLI, deploy universal-auth identity, lock down `/etc/infisical`            |
| `traefik`    | Copy traefik-prod/ configs, chmod 600 on acme.json                                 |
| `monitoring` | OTel collector config that forwards metrics/logs/traces to Grafana Cloud           |
| `app`        | `docker login`, `docker compose pull/up`, health-gated zero-downtime scale +1/-1   |

## Running locally (dry-run only — no host targeted by default)

```bash
cd prod/ansible
ansible-lint                            # syntax + best practices
ansible-playbook --syntax-check playbooks/site.yml -i inventories/prod/hosts.yml.example
```

For a real run see `docs/MIGRATION-TO-PROD.md`.
