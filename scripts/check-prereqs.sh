#!/usr/bin/env bash
# shellcheck source=./_lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/_lib.sh"

get_version() {
  case "$1" in
    docker)           docker --version 2>/dev/null | sed -E 's/^Docker version ([0-9]+\.[0-9]+\.[0-9]+).*/\1/' ;;
    "docker compose") docker compose version --short 2>/dev/null ;;
    bun)              bun --version 2>/dev/null ;;
    make)             make --version 2>/dev/null | head -n1 | awk '{print $NF}' ;;
    mkcert)           mkcert -version 2>/dev/null ;;
    jq)               jq --version 2>/dev/null ;;
    tmux)             tmux -V 2>/dev/null ;;
    age)              age --version 2>/dev/null ;;
    sops)             sops --version --disable-version-check 2>/dev/null | head -n1 | awk '{print $2}' ;;
    *)                echo unknown ;;
  esac
}

has_command() {
  if [[ "$1" == "docker compose" ]]; then
    docker compose version >/dev/null 2>&1
  else
    command -v "$1" >/dev/null 2>&1
  fi
}

# Format: "name|required|min_version|hint"
PREREQS=(
  "docker|yes|24.0.0|see https://docs.docker.com/engine/install/"
  "docker compose|yes||install Docker Desktop or docker-compose-plugin"
  "bun|no|1.1.38|curl -fsSL https://bun.sh/install | bash"
  "make|yes||apt install build-essential   |   brew install make"
  "mkcert|no||apt install mkcert   |   brew install mkcert"
  "jq|no||apt install jq   |   brew install jq"
  "tmux|no||apt install tmux   |   brew install tmux"
  "age|no||apt install age   |   brew install age"
  "sops|no||see https://github.com/getsops/sops/releases"
)

version_ge() {
  [[ "$(printf '%s\n%s\n' "$2" "$1" | sort -V | head -n1)" == "$2" ]]
}

print_row() {
  local name="$1" status="$2" detail="$3" color="$4"
  printf "%-18s ${color}%-10s${NC} %s\n" "$name" "$status" "$detail"
}

printf '\n%s=== Lumiris prerequisites check ===%s\n' "$BLUE" "$NC"
printf '%-18s %-10s %s\n' "TOOL" "STATUS" "VERSION/NOTE"
printf '%-18s %-10s %s\n' "------------------" "----------" "------------------------------"

REQUIRED_FAIL=0
HINTS=()

for entry in "${PREREQS[@]}"; do
  # Hint field can contain literal `|`, so split only the first 3 fields.
  name="${entry%%|*}";          rest="${entry#*|}"
  required="${rest%%|*}";       rest="${rest#*|}"
  minver="${rest%%|*}";         hint="${rest#*|}"

  if ! has_command "$name"; then
    if [[ "$required" == "yes" ]]; then
      print_row "$name" "MISSING" "(required)" "$RED"
      REQUIRED_FAIL=1
    else
      print_row "$name" "MISSING" "(optional)" "$YELLOW"
    fi
    HINTS+=("$name: $hint")
    continue
  fi

  ver="$(get_version "$name")"
  [[ -z "$ver" ]] && ver=unknown

  if [[ -z "$minver" ]]; then
    print_row "$name" "OK" "$ver" "$GREEN"
    continue
  fi

  if [[ "$ver" =~ ^[0-9] ]] && version_ge "$ver" "$minver"; then
    print_row "$name" "OK" "$ver" "$GREEN"
  else
    [[ "$required" == "yes" ]] && color="$RED" || color="$YELLOW"
    print_row "$name" "FAIL" "$ver (need >=$minver)" "$color"
    [[ "$required" == "yes" ]] && REQUIRED_FAIL=1
    HINTS+=("$name: $hint")
  fi
done

if (( ${#HINTS[@]} > 0 )); then
  printf "\n%sHints d'installation :%s\n" "$YELLOW" "$NC"
  printf '  - %s\n' "${HINTS[@]}"
fi

echo
if (( REQUIRED_FAIL == 0 )); then
  ok "Tous les prérequis obligatoires sont satisfaits."
else
  die "Des prérequis obligatoires manquent (docker / docker compose / make)."
fi
