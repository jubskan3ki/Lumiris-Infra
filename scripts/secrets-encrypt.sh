#!/usr/bin/env bash
# shellcheck source=./_lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/_lib.sh"

SECRETS_DIR="$ROOT/secrets"

command -v sops >/dev/null 2>&1 || die "[secrets-encrypt] sops not installed — https://github.com/getsops/sops"

shopt -s nullglob
encrypted=0
skipped=0

for file in "$SECRETS_DIR"/*.sops.yaml; do
  [[ "$file" == *.example ]] && continue

  if grep -q '^sops:' "$file" 2>/dev/null; then
    info "[secrets-encrypt] skip (already encrypted): $file"
    skipped=$((skipped + 1))
    continue
  fi

  info "[secrets-encrypt] encrypting: $file"
  sops --encrypt --in-place "$file"
  encrypted=$((encrypted + 1))
done

ok "[secrets-encrypt] done: $encrypted encrypted, $skipped already-encrypted"
