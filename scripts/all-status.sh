#!/usr/bin/env bash
# shellcheck source=./_lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/_lib.sh"

printf '%s--- tmux session %q ---%s\n' "$BLUE" "$SESSION" "$NC"
if command -v tmux >/dev/null 2>&1 && tmux has-session -t "$SESSION" 2>/dev/null; then
  ok "session running"
  tmux list-windows -t "$SESSION" -F "  #I: #W (#{window_panes} panes)" 2>/dev/null || true
else
  warn "session absente"
fi
echo

printf '%s--- docker compose ps ---%s\n' "$BLUE" "$NC"
if [[ -d "$LOCAL_DIR" ]] && docker info >/dev/null 2>&1; then
  (cd "$LOCAL_DIR" && docker compose ps) || warn "docker compose ps a échoué."
else
  warn "docker daemon down ou $LOCAL_DIR introuvable."
fi
echo

printf '%s--- Healthchecks containers ---%s\n' "$BLUE" "$NC"
if docker info >/dev/null 2>&1; then
  for c in postgres redis minio; do print_container_health "$c"; done
else
  warn "docker daemon down."
fi
echo

printf '%s--- URLs locales ---%s\n' "$BLUE" "$NC"
for entry in "${SERVICES[@]}"; do
  label="$(service_field "$entry" 1)"
  host="$(service_field "$entry"  2)"
  url="https://$host"
  code="$(http_status "$url")"
  if http_reachable "$code"; then
    color="$GREEN"
  else
    color="$RED"
  fi
  printf "  %-12s %-40s ${color}%s${NC}\n" "$label" "$url" "$code"
done
