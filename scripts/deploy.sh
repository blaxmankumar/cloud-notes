#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TF_DIR="$ROOT_DIR/terraform/environments/main"
ENVIRONMENT="${ENVIRONMENT:-main}"
TFVARS_FILE="${TFVARS_FILE:-$ROOT_DIR/terraform/environments/config/$ENVIRONMENT.tfvars}"
: "${TF_STATE_BUCKET:?Set TF_STATE_BUCKET to the bootstrapped S3 state bucket name}"
TF_STATE_KEY="${TF_STATE_KEY:-aws-verified-access-zero-trust/$ENVIRONMENT/terraform.tfstate}"
AWS_REGION="${AWS_REGION:-us-east-1}"

if [[ ! -f "$TFVARS_FILE" ]]; then
  echo "Missing $TFVARS_FILE. Copy terraform.tfvars.example and supply account-specific values." >&2
  exit 1
fi

terraform -chdir="$TF_DIR" init \
  -backend-config="bucket=$TF_STATE_BUCKET" \
  -backend-config="key=$TF_STATE_KEY" \
  -backend-config="region=$AWS_REGION" \
  -backend-config="use_lockfile=true"
terraform -chdir="$TF_DIR" plan -input=false -var-file="$TFVARS_FILE" -out=deployment.tfplan
echo "Review the plan above. Type APPLY to continue:"
read -r confirmation
[[ "$confirmation" == "APPLY" ]] || { echo "Deployment cancelled."; exit 1; }
terraform -chdir="$TF_DIR" apply -input=false deployment.tfplan
