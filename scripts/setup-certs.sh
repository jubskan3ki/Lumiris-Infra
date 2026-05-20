#!/usr/bin/env bash
# shellcheck source=./_lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/_lib.sh"

CERT_DIR="$LOCAL_DIR/traefik/certs"
CERT_FILE="$CERT_DIR/lumiris.local.crt"
KEY_FILE="$CERT_DIR/lumiris.local.key"

if ! command -v mkcert >/dev/null 2>&1; then
  err "mkcert n'est pas installé."
  cat <<'EOF'
Installation :
  - Debian/Ubuntu : sudo apt install mkcert libnss3-tools
  - macOS         : brew install mkcert nss
  - autre         : https://github.com/FiloSottile/mkcert#installation
EOF
  exit 1
fi

info "Vérification / installation de la CA mkcert locale..."
if mkcert -install >/dev/null 2>&1; then
  ok "CA mkcert prête."
else
  warn "mkcert -install a renvoyé une erreur (la CA est peut-être déjà installée)."
fi

mkdir -p "$CERT_DIR"

if [[ -f "$CERT_FILE" && -f "$KEY_FILE" ]] \
   && openssl x509 -in "$CERT_FILE" -noout -checkend 86400 >/dev/null 2>&1; then
  ok "Certificat existant valide (>24h restantes) : $CERT_FILE"
  info "Pour forcer la regénération : rm $CERT_FILE $KEY_FILE && rerun"
  exit 0
fi

[[ -f "$CERT_FILE" ]] && warn "Certificat existant expiré ou expirant sous 24h, regénération..."

info "Génération du certificat pour *.lumiris.local lumiris.local ..."
(
  cd "$CERT_DIR" || exit 1
  mkcert \
    -cert-file "lumiris.local.crt" \
    -key-file  "lumiris.local.key" \
    "*.lumiris.local" "lumiris.local"
)

if [[ -f "$CERT_FILE" && -f "$KEY_FILE" ]]; then
  ok "Certificat généré : $CERT_FILE"
  ok "Clé privée       : $KEY_FILE"
  info "Pense à relancer Traefik pour qu'il recharge les certificats :"
  info "  docker compose -f $LOCAL_DIR/docker-compose.yml restart traefik"
else
  die "Échec de la génération du certificat."
fi
