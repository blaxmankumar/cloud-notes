#!/usr/bin/env bash
set -euo pipefail

AWS_REGION="${AWS_REGION:-us-east-1}"
PROJECT_NAME="${PROJECT_NAME:-aws-verified-access-zero-trust}"
ENVIRONMENT="${ENVIRONMENT:-main}"

NAME_BASE="${PROJECT_NAME}-${ENVIRONMENT}"
TARGET_GROUP_NAME="${NAME_BASE:0:28}-app"
TARGET_GROUP_ARN="${TARGET_GROUP_ARN:-$(aws elbv2 describe-target-groups --region "$AWS_REGION" \
  --names "$TARGET_GROUP_NAME" --query 'TargetGroups[0].TargetGroupArn' --output text)}"
[[ "$TARGET_GROUP_ARN" != "None" ]] || { echo "Target group not found." >&2; exit 1; }

STATE="$(aws elbv2 describe-target-health --region "$AWS_REGION" --target-group-arn "$TARGET_GROUP_ARN" \
  --query 'TargetHealthDescriptions[0].TargetHealth.State' --output text)"
[[ "$STATE" == "healthy" ]] || { echo "ALB target state: $STATE" >&2; exit 1; }
echo "ALB target is healthy."

if [[ -n "${APPLICATION_URL:-}" ]]; then
  CODE="$(curl --silent --show-error --output /dev/null --write-out '%{http_code}' --max-time 20 "$APPLICATION_URL")"
  case "$CODE" in 200|302|401|403) echo "Verified Access boundary responded with HTTP $CODE." ;; *) echo "Unexpected HTTP $CODE." >&2; exit 1 ;; esac
fi
