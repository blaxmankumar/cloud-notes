#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TF_DIR="$ROOT_DIR/terraform/environments/main"

terraform -chdir="$TF_DIR" fmt -check -recursive
terraform -chdir="$TF_DIR" init -backend=false -input=false
terraform -chdir="$TF_DIR" validate

npm --prefix "$ROOT_DIR/backend" ci
npm --prefix "$ROOT_DIR/backend" test
npm --prefix "$ROOT_DIR/frontend" ci
npm --prefix "$ROOT_DIR/frontend" run build

grep -q 'email.verified == true' "$ROOT_DIR/policies/group-policy.cedar"
grep -q 'address like "\*@${approved_email_domain}"' "$ROOT_DIR/policies/group-policy.cedar"
grep -q 'approved_user_emails_cedar' "$ROOT_DIR/policies/group-policy.cedar"
grep -q 'groups has "${approved_identity_center_group_id}"' "$ROOT_DIR/policies/endpoint-policy.cedar"
echo "Validation completed successfully."
