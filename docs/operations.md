# Operations runbook

## Daily and weekly

- Review the CloudWatch EC2 status alarm, application health endpoint, and Free Tier credit balance.
- Confirm the EC2 SSM managed-node status and apply planned Amazon Linux/container dependency updates.
- Check S3 state/artifact growth and current billing forecast. Release artifacts expire after seven days.
- Weekly, sample denied events and compare them with expected test or threat activity.

## Access troubleshooting

Record attempt time, user (without tokens), expected domain/group, and endpoint. Check the Verified Access decision first, then Identity Center email verification/group membership, then ALB/app only for allowed requests. Denied requests should have no corresponding application request.

## Change approved domain or group

Update the protected Terraform variable/source tfvars on a branch. For a group change, use the immutable ID. Run a merge-request plan, require security/identity-owner review, merge, manually apply, and execute the full access matrix. Never leave console-only policy drift.

## Deployment

1. Review merge-request tests/scans/plan.
2. Merge to protected `main`.
3. Review the new main-branch plan artifact.
4. Authorize the manual `terraform_apply` job.
5. Observe SSM application deployment and public `/health` verification.
6. Open the Terraform `application_url`; never place sensitive data in Free Tier public mode.

## Alarm response

- Denials: determine expected tests vs brute force/incorrect assignment; preserve relevant log events.
- EC2 status failure: inspect the instance, Docker, disk space, bootstrap, and `/health` through SSM.
- SNS: confirm receipt and resolution; keep subscriptions current.

## State recovery

Stop all pipelines, preserve the current local/remote state, inspect S3 versions and lockfile ownership, then restore only the verified latest-good object. Run `terraform plan -refresh-only`, resolve imports/drift, then a normal plan. Never hand-edit state JSON.

## Security review

Quarterly review IAM CI permissions using Access Analyzer/CloudTrail, SG graph, OIDC subject restriction, Cedar owners, group membership, log retention, AMI/Node/container versions, artifact access, and break-glass audit records.
