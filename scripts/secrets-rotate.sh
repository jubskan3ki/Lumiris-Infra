#!/usr/bin/env bash
# shellcheck source=./_lib.sh
# Run after editing ../.sops.yaml recipients to re-key every encrypted secret.
source "$(dirname "${BASH_SOURCE[0]}")/_lib.sh"

SECRETS_DIR="$ROOT/secrets"

command -v sops >/dev/null 2>&1 || die "[secrets-rotate] sops not installed"
[[ -n "${SOPS_AGE_KEY_FILE:-}" && -r "${SOPS_AGE_KEY_FILE}" ]] \
  || die "[secrets-rotate] SOPS_AGE_KEY_FILE must be set and readable"

shopt -s nullglob
rotated=0
for file in "$SECRETS_DIR"/*.sops.yaml; do
  [[ "$file" == *.example ]] && continue

  if ! grep -q '^sops:' "$file" 2>/dev/null; then
    warn "[secrets-rotate] skip (not yet encrypted): $file"
    continue
  fi

  info "[secrets-rotate] rotating: $file"
  sops updatekeys --yes "$file"
  rotated=$((rotated + 1))
done

ok "[secrets-rotate] done: $rotated files rotated"
info "[secrets-rotate] commit the modified files now"
