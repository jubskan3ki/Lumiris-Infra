#!/usr/bin/env bash
# shellcheck source=./_lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/_lib.sh"

if tmux has-session -t "$SESSION" 2>/dev/null; then
  tmux kill-session -t "$SESSION" 2>/dev/null || true
  ok "tmux session '$SESSION' killed"
else
  info "tmux session '$SESSION' absente — rien à killer"
fi

if [[ -d "$LOCAL_DIR" ]]; then
  info "Arrêt de la stack docker compose (volumes préservés)..."
  (cd "$LOCAL_DIR" && docker compose down) || warn "docker compose down a renvoyé une erreur."
  ok "docker stack stopped"
else
  warn "Répertoire $LOCAL_DIR introuvable, skip docker compose down."
fi

echo
printf '%s=== Récap ===%s\n' "$GREEN" "$NC"
ok "tmux killed"
ok "docker stack stopped"
info "Volumes preserved (use \`make reset\` for full wipe)"
