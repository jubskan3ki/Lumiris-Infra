# GitHub Actions workflows

## Active

- **[`local-check.yml`](local-check.yml)** — runs on every push / PR. Three jobs:
  - `lint` — yamllint, shellcheck, hadolint, gitleaks, prettier
  - `terraform-validate` — `terraform fmt -check -recursive` then `init -backend=false` + `validate`
  - `ansible-lint` — `ansible-lint` against `prod/ansible/`

  Concurrency cancels in-progress runs on the same ref. Each job has a 10-minute timeout.

## Inert (workflow_dispatch only)

- **[`prod-terraform-plan.yml`](prod-terraform-plan.yml)** — decrypts
  `secrets/prod.env.sops.yaml` with `SOPS_AGE_KEY` (repo secret), runs
  `terraform plan` for the prod env, posts the plan to the job summary.
  Activate when bootstrap secrets are filled in (`docs/MIGRATION-TO-PROD.md` step 4).

- **[`prod-deploy.yml`](prod-deploy.yml)** — guarded by `env.VPS_DISPONIBLE='false'`.
  Refuses to run until you flip that to `'true'`. When active, takes a `tag`
  input (`v0.4.2`), decrypts secrets, materialises the inventory, and runs
  `ansible-playbook deploy.yml`. Inputs include a `force_recreate` toggle for
  cold-restart deploys.

## Coming later (placeholders, not files)

- Renovate (or Dependabot) for image tag bumps in `docker-compose.prod.yml`
  and pinned Terraform/Ansible versions.
- A `release-images.yml` per app repo (`Lumiris-Backend`, `Lumiris-Front`)
  that builds + pushes `ghcr.io/jubs-kan3ki/lumiris-*:vX.Y.Z` on tag push.

## Required repo secrets (set at activation time)

- `SOPS_AGE_KEY` — the private age key as text (`AGE-SECRET-KEY-...`). Used by
  `prod-terraform-plan.yml` and `prod-deploy.yml`.
- `GITHUB_TOKEN` — provided automatically by GitHub, used by gitleaks.

## Pinning policy

Every action is pinned to a released version (no `@main`, no floating tags).
When bumping, update both this README and the workflow file in the same commit.
