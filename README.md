# Lumiris-Infra

> Infrastructure & orchestration du Lumiris Ecosystem

Ce dépôt centralise tout ce qui permet de faire tourner localement (et bientôt en
production) la stack Lumiris : Docker compose, configuration Traefik, certificats
mkcert, scripts d'amorçage, monitoring, et orchestration des autres repos via
[mprocs](https://github.com/pvolok/mprocs).

## Layout

```text
~/Dev/Lumiris/
├── Lumiris-Front/      Monorepo Bun + Turbo (4 apps Next.js 16 + packages partages)
├── Lumiris-Backend/    API Spring Boot 3.4.5 / Java 21 (port 8080)
└── Lumiris-Infra/      Orchestration locale + prep prod (ce repo)
    ├── local/          Docker compose dev (Traefik, Postgres, Redis, MinIO, Mailhog, monitoring)
    ├── prod/           Stack containerisee pour deploiement futur (inerte)
    ├── scripts/        setup-hosts.sh, setup-certs.sh, smoke-test, secrets, seed
    ├── seed/           Jeux de donnees de seed
    ├── secrets/        SOPS + age (config initiale)
    ├── bench/          Outils de benchmark
    ├── .mise.toml      Toolchain dev (bun, java, jq, mkcert, age, sops, mprocs)
    ├── mprocs.yaml     Orchestration TUI infra + backend + front
    └── docs/           Documentation (ce dossier)
```

## Quickstart

### 1. Pré-requis système (à installer une fois)

- Docker Engine + Docker Compose v2
- `make`
- [`mise`](https://mise.jdx.dev) (`curl https://mise.run | sh`)

Tout le reste (bun, java 21, jq, mkcert, age, sops, mprocs, tmux) est géré par
`mise` via [`.mise.toml`](.mise.toml).

### 2. Installer la toolchain

```bash
cd ~/Dev/Lumiris/Lumiris-Infra
make tools                       # = mise install ; mise ls
mise activate zsh >> ~/.zshrc    # (une seule fois) auto-PATH dans les nouveaux shells
```

### 3. Setup initial (une seule fois)

```bash
make setup
```

Ce target enchaine :

- `setup-hosts.sh` — ajoute les vhosts `*.lumiris.local` dans `/etc/hosts`
- `setup-certs.sh` — genere les certificats locaux via `mkcert`
- Initialisation des fichiers `.env` a partir des `.env.example`

### 4. Démarrer la stack complète

```bash
make dev
```

Lance [mprocs](https://github.com/pvolok/mprocs) avec 3 process (cf. [`mprocs.yaml`](mprocs.yaml)) :

| Process   | Rôle                                                                 |
| --------- | -------------------------------------------------------------------- |
| `infra`   | `docker compose up` (Traefik + Postgres + Redis + MinIO + Mailhog)   |
| `backend` | `./mvnw spring-boot:run` dans Lumiris-Backend                        |
| `front`   | `bun dev` (Turbo orchestre les 4 apps) dans Lumiris-Front            |

Hotkeys mprocs : `↑↓` naviguer · `<Tab>` logs↔liste · `r` restart focus ·
`x` kill focus · `s` start arrêté · `q` quit (envoie SIGTERM à tous les process,
les containers s'arrêtent proprement).

> Pas d'auto-restart sur modif fichier : volontaire. Tu redémarres un process
> à la main avec `r` quand tu en as besoin.

## Stack locale

Tous les vhosts ci-dessous resolvent vers `127.0.0.1` (via `/etc/hosts`) puis sont
routes par Traefik vers leur cible.

| Vhost                   | Cible                | Description                    |
| ----------------------- | -------------------- | ------------------------------ |
| `lumiris.local`         | host:3000            | Site marketing (Next.js)       |
| `admin.lumiris.local`   | host:3001            | Back-office                    |
| `mobile.lumiris.local`  | host:3002            | App mobile (web + Tauri-ready) |
| `client.lumiris.local`  | host:3003            | Workspace artisans B2B         |
| `api.lumiris.local`     | host:8080            | API Spring Boot                |
| `traefik.lumiris.local` | traefik:8080         | Dashboard Traefik (basic auth) |
| `minio.lumiris.local`   | minio:9001           | MinIO Console                  |
| `cdn.lumiris.local`     | minio:9000           | MinIO S3 endpoint              |
| `pgadmin.lumiris.local` | pgadmin:80           | pgAdmin (profile `tools`)      |
| `redis.lumiris.local`   | redis-commander:8081 | Redis UI (profile `tools`)     |
| `mailhog.lumiris.local` | mailhog:8025         | Fake SMTP UI                   |
| `grafana.lumiris.local` | grafana:3000         | Grafana (profile `monitoring`) |

Voir [`docs/SERVICES.md`](docs/SERVICES.md) pour les credentials et les ports
exposes sur l'hote.

## Phase 2 — Production

Le dossier `prod/` est **inerte** mais complet : `docker-compose.prod.yml`
final, modules Terraform (Cloudflare DNS + R2 + Infisical + Grafana Cloud),
roles Ansible (common, docker, infisical, traefik, monitoring, app), configs
Traefik et OTel collector. Lint clean (`make prod-check`).

Quand le VPS sera disponible :

1. Suivre la checklist comptes externes : [`docs/ONBOARDING-PROD.md`](docs/ONBOARDING-PROD.md)
2. Remplir + chiffrer `secrets/prod.env.sops.yaml`
3. Remplir `prod/terraform/envs/prod/terraform.tfvars` + `prod/ansible/inventories/prod/hosts.yml`
4. Lancer `make prod-bootstrap` (interactif, refuse gracieusement tant qu'une pièce manque)

Détail complet : [`docs/MIGRATION-TO-PROD.md`](docs/MIGRATION-TO-PROD.md). Coûts attendus : [`docs/COSTS.md`](docs/COSTS.md).

## Repos lies

- [`../Lumiris-Front/`](../Lumiris-Front/) — front (monorepo Bun + Turbo)
- [`../Lumiris-Backend/`](../Lumiris-Backend/) — API Spring Boot

## Docs

- [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) — vision d'ensemble + diagramme
- [`docs/LOCAL.md`](docs/LOCAL.md) — guide local pas-a-pas
- [`docs/SERVICES.md`](docs/SERVICES.md) — services + credentials + ports
- [`docs/TROUBLESHOOTING.md`](docs/TROUBLESHOOTING.md) — symptomes / causes / fix
- [`docs/RUNBOOK.md`](docs/RUNBOOK.md) — procedures ops (local + prod)
- [`docs/ONBOARDING.md`](docs/ONBOARDING.md) — checklist nouveau dev
- [`docs/MIGRATION-TO-PROD.md`](docs/MIGRATION-TO-PROD.md) — plan d'activation prod
- [`docs/ONBOARDING-PROD.md`](docs/ONBOARDING-PROD.md) — comptes externes à créer
- [`docs/COSTS.md`](docs/COSTS.md) — coûts attendus (free tiers)
