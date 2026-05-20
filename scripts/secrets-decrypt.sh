#!/usr/bin/env bash
# shellcheck source=./_lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/_lib.sh"

usage() {
  cat <<'EOF'
Usage: secrets-decrypt.sh [-o OUTPUT] <file>

  <file>     Path to the encrypted sops file (e.g. secrets/prod.env.sops.yaml)
  -o OUTPUT  Write decrypted content to OUTPUT instead of stdout
EOF
  exit "${1:-0}"
}

output=""
while getopts ":o:h" opt; do
  case "$opt" in
    o) output="$OPTARG" ;;
    h) usage 0 ;;
    *) usage 2 ;;
  esac
done
shift $((OPTIND - 1))

(( $# == 1 )) || usage 2
readonly file="$1"

command -v sops >/dev/null 2>&1                       || die "[secrets-decrypt] sops not installed"
[[ -n "${SOPS_AGE_KEY_FILE:-}" ]]                     || die "[secrets-decrypt] SOPS_AGE_KEY_FILE is unset — point it at your age private key"
[[ -r "$SOPS_AGE_KEY_FILE" ]]                         || die "[secrets-decrypt] cannot read \$SOPS_AGE_KEY_FILE ($SOPS_AGE_KEY_FILE)"
[[ -f "$file" ]]                                      || die "[secrets-decrypt] no such file: $file"

if [[ -n "$output" ]]; then
  sops --decrypt "$file" > "$output"
  chmod 600 "$output"
  info "[secrets-decrypt] wrote $output (chmod 600)"
else
  sops --decrypt "$file"
fi
