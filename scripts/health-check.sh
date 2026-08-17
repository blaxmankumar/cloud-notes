#!/usr/bin/env bash
set -euo pipefail

AWS_REGION="${AWS_REGION:-us-east-1}"
PROJECT_NAME="${PROJECT_NAME:-aws-verified-access-zero-trust}"
ENVIRONMENT="${ENVIRONMENT:-main}"

INSTANCE_IP="${EC2_PUBLIC_IP:-$(aws ec2 describe-instances --region "$AWS_REGION" \
  --filters "Name=tag:Project,Values=$PROJECT_NAME" "Name=tag:Environment,Values=$ENVIRONMENT" "Name=instance-state-name,Values=running" \
  --query 'Reservations[].Instances[] | [0].PublicIpAddress' --output text)}"

if [[ -n "$INSTANCE_IP" && "$INSTANCE_IP" != "None" ]]; then
  APPLICATION_URL="${APPLICATION_URL:-http://${INSTANCE_IP}:8000/health}"
  for _ in $(seq 1 30); do
    CODE="$(curl --silent --output /dev/null --write-out '%{http_code}' --max-time 10 "$APPLICATION_URL" || true)"
    [[ "$CODE" == "200" ]] && { echo "Free Tier application is healthy at $APPLICATION_URL."; exit 0; }
    sleep 10
  done
  echo "Application health check failed at $APPLICATION_URL (last HTTP $CODE)." >&2
  exit 1
fi

NAME_BASE="${PROJECT_NAME}-${ENVIRONMENT}"
TARGET_GROUP_NAME="${NAME_BASE:0:28}-app"
TARGET_GROUP_ARN="${TARGET_GROUP_ARN:-$(aws elbv2 describe-target-groups --region "$AWS_REGION" \
  --names "$TARGET_GROUP_NAME" --query 'TargetGroups[0].TargetGroupArn' --output text)}"
[[ "$TARGET_GROUP_ARN" != "None" ]] || { echo "Neither a public EC2 address nor a target group was found." >&2; exit 1; }

STATE="$(aws elbv2 describe-target-health --region "$AWS_REGION" --target-group-arn "$TARGET_GROUP_ARN" \
  --query 'TargetHealthDescriptions[0].TargetHealth.State' --output text)"
[[ "$STATE" == "healthy" ]] || { echo "ALB target state: $STATE" >&2; exit 1; }
echo "ALB target is healthy."

if [[ -n "${APPLICATION_URL:-}" ]]; then
  CODE="$(curl --silent --show-error --output /dev/null --write-out '%{http_code}' --max-time 20 "$APPLICATION_URL")"
  case "$CODE" in 200|302|401|403) echo "Verified Access boundary responded with HTTP $CODE." ;; *) echo "Unexpected HTTP $CODE." >&2; exit 1 ;; esac
fi
