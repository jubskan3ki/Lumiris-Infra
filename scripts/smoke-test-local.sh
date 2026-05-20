#!/usr/bin/env bash
# shellcheck source=./_lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/_lib.sh"

# Format: "label|url|expected_code"
GET_TARGETS=(
  "Site         |https://lumiris.local/|200"
  "API actuator |https://api.lumiris.local/actuator/health|200"
  "Admin        |https://admin.lumiris.local/|200"
  "Client       |https://client.lumiris.local/|200"
  "Mobile       |https://mobile.lumiris.local/|200"
)

# Payload schema must match WebVitalDto (name ∈ CLS|LCP|FID|INP|TTFB|FCP, app ∈ admin|site|client|mobile).
TELEMETRY_URL="https://api.lumiris.local/api/telemetry/web-vitals"
TELEMETRY_EXPECTED="204"
WEB_VITAL_PAYLOAD='{"name":"LCP","value":1234.5,"rating":"good","sessionId":"smoke-test-session","app":"site","route":"/smoke","navigationType":"navigate","timestamp":1715000000000}'

info "Smoke test local (curl -k, timeout 5s par requête)..."
echo

FAILED=0
RESULTS=()

check() {
  local label="$1" url="$2" expected="$3" code="$4"
  if [[ "$code" == "$expected" ]]; then
    printf "  ${GREEN}[ ok ]${NC} %-14s %-50s -> %s (expected %s)\n" "$label" "$url" "$code" "$expected"
    RESULTS+=("OK   $label $url $code")
  else
    printf "  ${RED}[fail]${NC} %-14s %-50s -> %s (expected %s)\n" "$label" "$url" "$code" "$expected"
    RESULTS+=("FAIL $label $url $code (expected $expected)")
    FAILED=$((FAILED + 1))
  fi
}

for entry in "${GET_TARGETS[@]}"; do
  IFS='|' read -r label url expected <<<"$entry"
  label="${label%"${label##*[![:space:]]}"}"   # rtrim
  check "$label" "$url" "$expected" "$(http_status "$url" 5)"
done

# http_status() only does GET, so inline the curl for the telemetry POST.
code="$(curl -k -s -o /dev/null -w '%{http_code}' --max-time 5 \
  -X POST "$TELEMETRY_URL" \
  -H 'Content-Type: application/json' \
  -d "$WEB_VITAL_PAYLOAD" 2>/dev/null || echo DOWN)"
check "Telemetry POST" "$TELEMETRY_URL" "$TELEMETRY_EXPECTED" "$code"

TOTAL=$((${#GET_TARGETS[@]} + 1))
echo
if (( FAILED == 0 )); then
  ok "Tous les smoke tests passent ($TOTAL/$TOTAL)."
  exit 0
fi

err "Smoke tests échoués : $FAILED/$TOTAL"
echo
printf "%sRécap :%s\n" "$YELLOW" "$NC"
printf '  %s\n' "${RESULTS[@]}"
exit 1
