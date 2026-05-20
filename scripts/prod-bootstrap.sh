#!/usr/bin/env bash
# shellcheck source=./_lib.sh
# Idempotent first-deploy orchestrator; refuses to run until sops/age/inventory/tfvars are ready.
source "$(dirname "${BASH_SOURCE[0]}")/_lib.sh"

readonly SOPS_BOOTSTRAP="$ROOT/secrets/prod.env.sops.yaml"
readonly TF_DIR="$ROOT/prod/terraform"
readonly TF_TFVARS="$TF_DIR/envs/prod/terraform.tfvars"
readonly ANSIBLE_DIR="$ROOT/prod/ansible"
readonly ANSIBLE_INV="$ANSIBLE_DIR/inventories/prod/hosts.yml"

die() {
  err "$*"
  printf '%s[bootstrap] Read docs/MIGRATION-TO-PROD.md, fix the issue, then re-run.%s\n' "$YELLOW" "$NC" >&2
  exit 1
}

step "1/8 Prereq check"
for bin in sops terraform ansible-playbook docker; do
  command -v "$bin" >/dev/null 2>&1 || die "$bin is not installed"
done

step "2/8 Bootstrap secrets"
[[ -f "$SOPS_BOOTSTRAP" ]] || die "$SOPS_BOOTSTRAP not found (see step 3 of MIGRATION-TO-PROD.md)"
grep -q '^sops:' "$SOPS_BOOTSTRAP" || die "$SOPS_BOOTSTRAP is in cleartext — run 'sops -e -i $SOPS_BOOTSTRAP' first"
[[ -n "${SOPS_AGE_KEY_FILE:-}" ]] || die "SOPS_AGE_KEY_FILE is unset — point at your age private key"
[[ -r "$SOPS_AGE_KEY_FILE" ]]    || die "SOPS_AGE_KEY_FILE ($SOPS_AGE_KEY_FILE) is not readable"
sops --decrypt "$SOPS_BOOTSTRAP" >/dev/null || die "sops decrypt failed — your age key is not on the recipient list"

step "3/8 Terraform inputs"
[[ -f "$TF_TFVARS" ]] || die "$TF_TFVARS not found — copy from envs/prod/terraform.tfvars.example and fill in"
grep -q 'REPLACE_ME' "$TF_TFVARS" && die "$TF_TFVARS still contains REPLACE_ME placeholders"

step "4/8 Ansible inventory"
[[ -f "$ANSIBLE_INV" ]] || die "$ANSIBLE_INV not found — copy from hosts.yml.example and fill in"
grep -q 'REPLACE_ME' "$ANSIBLE_INV" && die "$ANSIBLE_INV still contains REPLACE_ME placeholders"

step "5/8 Terraform plan"
(cd "$TF_DIR" && terraform init -input=false)
(cd "$TF_DIR" && terraform plan -var-file=envs/prod/terraform.tfvars -input=false -out=tfplan.bin)
confirm "Apply the plan above?"
(cd "$TF_DIR" && terraform apply -input=false tfplan.bin)
(cd "$TF_DIR" && rm -f tfplan.bin)

step "6/8 Push secrets to Infisical"
cat <<EOF
${YELLOW}[bootstrap] Terraform outputs sensitive values you must push to Infisical now.${NC}
${YELLOW}  Suggested workflow:${NC}
    terraform -chdir=$TF_DIR output -json > /tmp/tf-out.json
    # puis pour chaque clé sensible, push vers Infisical /infra :
    infisical secrets set R2_ACCESS_KEY=\$(jq -r .r2_access_key_id.value /tmp/tf-out.json) --env=prod --path=/infra
    # ...répéter pour r2_secret_access_key, backup_passphrase, grafana_cloud_token, etc.
    shred -u /tmp/tf-out.json
EOF
confirm "Have you pushed the Terraform outputs to Infisical?"

step "7/8 Ansible bootstrap (hardening + docker + infisical)"
confirm "Run bootstrap playbook against the VPS (uses root@:22 from the inventory)?"
(cd "$ANSIBLE_DIR" && ansible-playbook playbooks/bootstrap.yml)

step "7b/8 Ansible deploy (first app rollout)"
INITIAL_TAG="${INITIAL_TAG:-latest}"
info "Initial deploy will use IMAGE_TAG=$INITIAL_TAG"
(cd "$ANSIBLE_DIR" && ansible-playbook playbooks/deploy.yml -e image_tag="$INITIAL_TAG")

step "8/8 Production seed"
confirm "Apply seed data (creates an admin user, plans, optional demo artisan)?"
"$ROOT/seed/apply-seed.sh" prod

step "Smoke tests"
DOMAIN="$(grep -E '^domain' "$TF_TFVARS" | head -1 | sed -E 's/.*"([^"]+)".*/\1/')"
for url in "https://$DOMAIN/" \
           "https://api.$DOMAIN/actuator/health" \
           "https://admin.$DOMAIN/" \
           "https://client.$DOMAIN/" \
           "https://mobile.$DOMAIN/"; do
  if curl -fsSL -o /dev/null "$url"; then
    printf '  %s✓%s %s\n' "$GREEN" "$NC" "$url"
  else
    printf '  %s✗%s %s\n' "$RED"   "$NC" "$url"
  fi
done

cat <<EOF

${GREEN}═══════════════════════════════════════════════════════════════════${NC}
${GREEN}  ✓ Prod bootstrap complete${NC}
${GREEN}═══════════════════════════════════════════════════════════════════${NC}

Next steps:
  1. Retrieve the seeded admin password:
       infisical secrets get SEED_ADMIN_PASSWORD_GENERATED --env=prod --path=/backend --plain
  2. Log in once, rotate the password.
  3. Delete the generated secret:
       infisical secrets delete SEED_ADMIN_PASSWORD_GENERATED --env=prod --path=/backend
  4. Flip env.VPS_DISPONIBLE to 'true' in .github/workflows/prod-deploy.yml
     so CI/CD deploys are enabled.
EOF
