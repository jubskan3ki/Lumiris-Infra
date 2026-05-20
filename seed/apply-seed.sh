#!/usr/bin/env bash
# Usage: ./seed/apply-seed.sh <env>  (env: dev|staging|prod, sourced from Infisical /backend).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <env>" >&2
  exit 2
fi
readonly ENV="$1"

for bin in infisical openssl htpasswd psql shred; do
  if ! command -v "$bin" >/dev/null 2>&1; then
    echo "[seed] missing dependency: $bin" >&2
    exit 1
  fi
done

echo "[seed] loading SPRING_DATASOURCE_* from Infisical (env=$ENV, path=/backend)"
TMP_ENV="$(mktemp)"
readonly TMP_ENV
chmod 600 "$TMP_ENV"
trap 'shred -u "$TMP_ENV" 2>/dev/null || rm -f "$TMP_ENV"' EXIT

infisical export --env="$ENV" --path=/backend --format=dotenv >"$TMP_ENV"
set -a
# shellcheck source=/dev/null
. "$TMP_ENV"
set +a

if [[ -z "${SPRING_DATASOURCE_URL:-}" ]]; then
  echo "[seed] SPRING_DATASOURCE_URL not present in Infisical /backend (env=$ENV)" >&2
  exit 1
fi

# Convert Spring jdbc:postgresql://... to a libpq URL.
PSQL_URL="${SPRING_DATASOURCE_URL#jdbc:}"
export PGPASSWORD="${SPRING_DATASOURCE_PASSWORD:-}"
PSQL_OPTS=(
  "$PSQL_URL"
  -U "${SPRING_DATASOURCE_USERNAME:?Missing SPRING_DATASOURCE_USERNAME in Infisical}"
  -v ON_ERROR_STOP=1
  --quiet
  --no-psqlrc
)

ADMIN_EMAIL="${SEED_ADMIN_EMAIL:-ops@lumiris.eu}"
SEED_ADMIN_PASSWORD="$(openssl rand -base64 32 | tr -d '\n=' | head -c 32)"
echo "[seed] generated SEED_ADMIN_PASSWORD (32 chars, base64) for $ADMIN_EMAIL"

# htpasswd -nbB produces $2y$, Spring Security wants $2a$ — substitute.
ADMIN_PW_HASH="$(htpasswd -nbB -C 12 admin "$SEED_ADMIN_PASSWORD" | cut -d: -f2)"
ADMIN_PW_HASH="${ADMIN_PW_HASH/\$2y\$/\$2a\$}"

shopt -s nullglob
for sql in "$SCRIPT_DIR"/00*.sql; do
  echo "[seed] applying: $(basename "$sql")"
  psql "${PSQL_OPTS[@]}" \
    -v admin_email="$ADMIN_EMAIL" \
    -v admin_pw_hash="$ADMIN_PW_HASH" \
    -f "$sql"
done

echo "[seed] storing SEED_ADMIN_PASSWORD_GENERATED in Infisical (delete after retrieval)"
infisical secrets set \
  "SEED_ADMIN_PASSWORD_GENERATED=$SEED_ADMIN_PASSWORD" \
  --env="$ENV" \
  --path=/backend \
  --type=shared >/dev/null

unset ADMIN_PW_HASH SEED_ADMIN_PASSWORD

cat <<EOF

────────────────────────────────────────────────────────────────────────
[seed] DONE — environment=$ENV
  Admin email : $ADMIN_EMAIL
  Password    : stored in Infisical → /backend/SEED_ADMIN_PASSWORD_GENERATED
                (visible ONCE; delete after handing it off)

Next steps
  1. Fetch the password:
       infisical secrets get SEED_ADMIN_PASSWORD_GENERATED --env=$ENV --path=/backend --plain
  2. Hand it to the human (1Password / Bitwarden / out-of-band channel).
  3. Delete the secret:
       infisical secrets delete SEED_ADMIN_PASSWORD_GENERATED --env=$ENV --path=/backend
  4. Ask the admin to log in and change the password immediately.
────────────────────────────────────────────────────────────────────────
EOF
