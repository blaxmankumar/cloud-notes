#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_NAME="${PROJECT_NAME:-aws-verified-access-zero-trust}"
ENVIRONMENT="${ENVIRONMENT:-dev}"
AWS_REGION="${AWS_REGION:-us-east-1}"
ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
BUCKET="${APP_ARTIFACT_BUCKET:-${PROJECT_NAME}-${ENVIRONMENT}-${ACCOUNT_ID}-artifacts}"
INSTANCE_ID="${EC2_INSTANCE_ID:-$(aws ec2 describe-instances --region "$AWS_REGION" \
  --filters "Name=tag:Project,Values=$PROJECT_NAME" "Name=tag:Environment,Values=$ENVIRONMENT" "Name=instance-state-name,Values=running" \
  --query 'Reservations[].Instances[] | [0].InstanceId' --output text)}"

if [[ -z "$INSTANCE_ID" || "$INSTANCE_ID" == "None" ]]; then
  echo "No running application EC2 instance found." >&2
  exit 1
fi

ARTIFACT="/tmp/cloud-notes-${CI_COMMIT_SHA:-local}.tgz"
tar -C "$ROOT_DIR" --exclude='.git' --exclude='node_modules' --exclude='dist' --exclude='terraform' \
  -czf "$ARTIFACT" backend frontend deploy/docker-compose.aws.yml deploy/nginx-verified-access.conf
aws s3 cp "$ARTIFACT" "s3://$BUCKET/releases/$(basename "$ARTIFACT")" --region "$AWS_REGION" --sse AES256

REMOTE_ARTIFACT="s3://$BUCKET/releases/$(basename "$ARTIFACT")"
COMMAND_ID="$(aws ssm send-command --region "$AWS_REGION" --instance-ids "$INSTANCE_ID" \
  --document-name AWS-RunShellScript --comment "Deploy Cloud Notes ${CI_COMMIT_SHA:-local}" \
  --parameters "commands=[\"aws s3 cp $REMOTE_ARTIFACT /tmp/cloud-notes.tgz\",\"rm -rf /opt/cloud-notes/release && mkdir -p /opt/cloud-notes/release\",\"tar -xzf /tmp/cloud-notes.tgz -C /opt/cloud-notes/release\",\"docker network create cloud-notes 2>/dev/null || true\",\"docker volume create cloud-notes-data\",\"cd /opt/cloud-notes/release && docker build -t cloud-notes-backend:current backend\",\"cd /opt/cloud-notes/release && docker build -t cloud-notes-frontend:current frontend\",\"docker rm -f cloud-notes-frontend cloud-notes-backend 2>/dev/null || true\",\"docker run -d --name cloud-notes-backend --restart unless-stopped --network cloud-notes --security-opt no-new-privileges -e DB_MODE=file -e DATA_FILE=/var/lib/cloud-notes/notes.json -e NODE_ENV=production -v cloud-notes-data:/var/lib/cloud-notes cloud-notes-backend:current\",\"docker run -d --name cloud-notes-frontend --restart unless-stopped --network cloud-notes --security-opt no-new-privileges -p 8000:80 -v /opt/cloud-notes/release/deploy/nginx-verified-access.conf:/etc/nginx/conf.d/default.conf:ro cloud-notes-frontend:current\",\"docker image prune -f\"]" \
  --query 'Command.CommandId' --output text)"

for _ in $(seq 1 60); do
  STATUS="$(aws ssm get-command-invocation --region "$AWS_REGION" --command-id "$COMMAND_ID" --instance-id "$INSTANCE_ID" --query Status --output text 2>/dev/null || true)"
  case "$STATUS" in
    Success) echo "Application deployed to $INSTANCE_ID."; exit 0 ;;
    Failed|Cancelled|TimedOut)
      aws ssm get-command-invocation --region "$AWS_REGION" --command-id "$COMMAND_ID" --instance-id "$INSTANCE_ID" --output json
      exit 1 ;;
  esac
  sleep 10
done
echo "Timed out waiting for SSM deployment command $COMMAND_ID." >&2
exit 1
