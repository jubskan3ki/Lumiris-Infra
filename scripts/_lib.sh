#!/usr/bin/env bash
[[ -n "${_LUMIRIS_LIB_LOADED:-}" ]] && return 0
_LUMIRIS_LIB_LOADED=1

set -euo pipefail
IFS=$'\n\t'

GREEN=$'\033[1;32m'
RED=$'\033[1;31m'
YELLOW=$'\033[1;33m'
BLUE=$'\033[1;34m'
NC=$'\033[0m'

info() { printf "%s[info]%s %s\n" "$BLUE"   "$NC" "$*"; }
ok()   { printf "%s[ ok ]%s %s\n" "$GREEN"  "$NC" "$*"; }
warn() { printf "%s[warn]%s %s\n" "$YELLOW" "$NC" "$*"; }
err()  { printf "%s[fail]%s %s\n" "$RED"    "$NC" "$*" >&2; }

die() {
  err "$*"
  exit 1
}

step() {
  printf '\n%s══ %s ══%s\n' "$GREEN" "$*" "$NC"
}

confirm() {
  local prompt="${1:-Continue?}"
  read -r -p "$(printf '%s%s%s [yes/N] ' "$YELLOW" "$prompt" "$NC")" ans
  [[ "$ans" == "yes" ]] || die "aborted by user"
}

LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$LIB_DIR/.." && pwd)"
LOCAL_DIR="$ROOT/local"
SCRIPTS_DIR="$ROOT/scripts"
SESSION="lumiris"
export ROOT LOCAL_DIR SCRIPTS_DIR SESSION

# Format: "label|host|description"
SERVICES=(
  "Site      |lumiris.local         |Vitrine (host:3000)"
  "Admin     |admin.lumiris.local   |Admin (host:3001)"
  "Mobile    |mobile.lumiris.local  |Mobile (host:3002)"
  "Client    |client.lumiris.local  |Client (host:3003)"
  "API       |api.lumiris.local     |API Spring Boot (host:8080)"
  "Traefik   |traefik.lumiris.local |Traefik dashboard"
  "MinIO     |minio.lumiris.local   |MinIO Console"
  "CDN       |cdn.lumiris.local     |MinIO S3 endpoint"
  "MailHog   |mailhog.lumiris.local |MailHog UI"
  "Grafana   |grafana.lumiris.local |Grafana (profile monitoring)"
  "pgAdmin   |pgadmin.lumiris.local |pgAdmin (profile tools)"
  "Redis UI  |redis.lumiris.local   |Redis Commander (profile tools)"
)

_trim() { local s="$*"; s="${s#"${s%%[![:space:]]*}"}"; s="${s%"${s##*[![:space:]]}"}"; printf '%s' "$s"; }

service_field() {
  local entry="$1" idx="$2" IFS='|'
  read -r f1 f2 f3 <<<"$entry"
  case "$idx" in
    1) _trim "$f1" ;;
    2) _trim "$f2" ;;
    3) _trim "$f3" ;;
  esac
}

print_urls_table() {
  printf '\n%sURLs locales%s\n' "$YELLOW" "$NC"
  local entry label host desc
  for entry in "${SERVICES[@]}"; do
    label="$(service_field "$entry" 1)"
    host="$(service_field "$entry" 2)"
    desc="$(service_field "$entry" 3)"
    printf "  %-12s https://%-26s %s\n" "$label" "$host" "$desc"
  done
}

# Prints: healthy|starting|unhealthy|no-health|absent.
container_health() {
  local name="$1" cid status
  cid="$(docker ps --filter "name=$name" --format '{{.ID}}' 2>/dev/null | head -n1)"
  if [[ -z "$cid" ]]; then
    printf 'absent'
    return
  fi
  status="$(docker inspect --format='{{if .State.Health}}{{.State.Health.Status}}{{else}}no-health{{end}}' "$cid" 2>/dev/null || echo unknown)"
  printf '%s' "$status"
}

print_container_health() {
  local name="$1" status color
  status="$(container_health "$name")"
  case "$status" in
    healthy)             color="$GREEN" ;;
    starting|no-health)  color="$YELLOW" ;;
    *)                   color="$RED" ;;
  esac
  printf "  %-12s %s%s%s\n" "$name" "$color" "$status" "$NC"
}

# Args: container_name [timeout_seconds=60]
wait_for_healthy() {
  local name="$1" timeout="${2:-60}"
  local deadline=$(( SECONDS + timeout ))
  local status
  while (( SECONDS < deadline )); do
    status="$(container_health "$name")"
    case "$status" in
      healthy)
        ok "$name : healthy"
        return 0
        ;;
      no-health)
        if docker inspect --format='{{.State.Running}}' \
             "$(docker ps --filter "name=$name" --format '{{.ID}}' | head -n1)" 2>/dev/null | grep -q true; then
          warn "$name : pas de healthcheck mais running"
          return 0
        fi
        ;;
    esac
    printf '  %s : %s ...\r' "$name" "$status"
    sleep 2
  done
  echo
  warn "$name : timeout ${timeout}s atteint (la stack continue de démarrer)."
  return 1
}

# Args: url [timeout=2]; prints status code or "DOWN".
http_status() {
  local url="$1" timeout="${2:-2}"
  curl -k -s -o /dev/null -w '%{http_code}' --max-time "$timeout" "$url" 2>/dev/null || echo DOWN
}

http_reachable() {
  case "$1" in
    2*|3*|401|403) return 0 ;;
    *)             return 1 ;;
  esac
}
