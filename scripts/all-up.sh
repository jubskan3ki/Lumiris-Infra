#!/usr/bin/env bash
# shellcheck source=./_lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/_lib.sh"

FRONT_DIR="$ROOT/../Lumiris-Front"
BACKEND_DIR="$ROOT/../Lumiris-Backend"

info "Pré-checks..."
command -v tmux >/dev/null 2>&1 || die "tmux n'est pas installé (apt install tmux | brew install tmux)."
ok "tmux présent."

docker info >/dev/null 2>&1 || die "Docker daemon indisponible. Démarre Docker puis relance."
ok "docker daemon up."

[[ -d "$FRONT_DIR" ]]   || die "Répertoire Lumiris-Front introuvable : $FRONT_DIR"
ok "Lumiris-Front trouvé."
[[ -d "$BACKEND_DIR" ]] || die "Répertoire Lumiris-Backend introuvable : $BACKEND_DIR"
ok "Lumiris-Backend trouvé."

if ! grep -qE "(^|[[:space:]])lumiris\.local([[:space:]]|$)" /etc/hosts 2>/dev/null; then
  err "lumiris.local n'est pas dans /etc/hosts."
  info "Lance \`make setup\` (ou scripts/setup-hosts.sh) avant de relancer."
  exit 1
fi
ok "/etc/hosts configuré."

info "Nettoyage d'une éventuelle session tmux '$SESSION' existante..."
tmux kill-session -t "$SESSION" 2>/dev/null || true

info "Création de la session tmux '$SESSION' (4 windows)..."
unset COMPOSE_FILE COMPOSE_PROFILES COMPOSE_PATH_SEPARATOR 2>/dev/null || true

tmux new-session -d -s "$SESSION" -n infra \
  -c "$LOCAL_DIR" \
  "unset COMPOSE_FILE COMPOSE_PROFILES; docker compose up; exec bash"

# shellcheck disable=SC2016  # single-quotes intentional: expansion happens inside tmux at runtime
tmux new-window -t "$SESSION":2 -n backend \
  -c "$BACKEND_DIR" \
  'export SDKMAN_DIR="$HOME/.sdkman"; [ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ] && source "$SDKMAN_DIR/bin/sdkman-init.sh"; if [ -f .env ]; then set -a && source .env && set +a; fi; ./mvnw spring-boot:run; exec bash'

tmux new-window -t "$SESSION":3 -n front \
  -c "$FRONT_DIR" \
  "bun dev; exec bash"

# shellcheck disable=SC2016
tmux new-window -t "$SESSION":4 -n status \
  -c "$ROOT" \
  'while true; do clear; echo "=== STATUS $(date '"'"'+%H:%M:%S'"'"') ==="; (cd '"$LOCAL_DIR"' && docker compose ps); echo; '"$SCRIPTS_DIR"'/all-status.sh 2>/dev/null || true; sleep 5; done'

ok "Session tmux '$SESSION' créée (4 windows : infra, backend, front, status)."

info "Attente que postgres et redis soient healthy (timeout 60s)..."
wait_for_healthy postgres || true
wait_for_healthy redis    || true

echo
printf '%s=== Lumiris stack démarrée ===%s\n' "$GREEN" "$NC"
print_urls_table
echo
ok "Stack démarrée. \`tmux attach -t $SESSION\` pour les logs."
