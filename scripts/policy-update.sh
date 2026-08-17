#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TF_DIR="$ROOT_DIR/terraform/environments/dev"
ENVIRONMENT="${ENVIRONMENT:-dev}"
: "${TF_STATE_BUCKET:?Set TF_STATE_BUCKET to the bootstrapped S3 state bucket name}"
: "${APPROVED_EMAIL_DOMAIN:?Set APPROVED_EMAIL_DOMAIN}"
: "${APPROVED_IDENTITY_CENTER_GROUP_ID:?Set APPROVED_IDENTITY_CENTER_GROUP_ID}"
TF_STATE_KEY="${TF_STATE_KEY:-aws-verified-access-zero-trust/$ENVIRONMENT/terraform.tfstate}"
AWS_REGION="${AWS_REGION:-us-east-1}"

terraform -chdir="$TF_DIR" init \
  -backend-config="bucket=$TF_STATE_BUCKET" \
  -backend-config="key=$TF_STATE_KEY" \
  -backend-config="region=$AWS_REGION" \
  -backend-config="use_lockfile=true"
terraform -chdir="$TF_DIR" plan \
  -var="environment=$ENVIRONMENT" \
  -var="enable_verified_access=true" \
  -var="approved_email_domain=$APPROVED_EMAIL_DOMAIN" \
  -var="approved_identity_center_group_id=$APPROVED_IDENTITY_CENTER_GROUP_ID"

echo "This command only produced a plan. Commit the variable/policy change and use the reviewed GitHub Actions apply job."
