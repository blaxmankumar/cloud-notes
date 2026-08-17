# AWS Verified Access Zero Trust for Cloud Notes

Production-style AWS infrastructure that protects the existing React/Node Cloud Notes application with AWS Verified Access, IAM Identity Center, and two independent Cedar authorization gates.

The application is never internet-addressable. Users reach `https://secure.lax-man.in`; Verified Access authenticates with IAM Identity Center, the group policy requires a verified corporate-domain address or an explicitly approved full email, and the endpoint policy requires an immutable Identity Center group ID. Only then can traffic reach the internal ALB and private EC2 target.

## Architecture

```text
User -> external DNS CNAME -> Verified Access (TLS + Identity Center + Cedar)
     -> internal ALB:80 -> private EC2:8000 -> React/Nginx -> Node API
```

Access logs flow to CloudWatch Logs, a documented OCSF metric filter counts denials, CloudWatch alarms notify an SNS topic, and GitHub Actions deploys through short-lived AWS OIDC credentials. See [architecture](docs/architecture.md) and [access flow](docs/access-flow.md).

## Important application choice

This repository started as the supplied React/Node Cloud Notes application, so it intentionally uses that application instead of replacing it with the Flask sample mentioned in the baseline. AWS deployment defaults to a file-backed note store on the encrypted EC2 EBS volume, avoiding RDS cost. The original MySQL mode remains available with `DB_MODE=mysql` and the `DB_*` settings. The single-instance file store is suitable for this demo, not a horizontally scaled production data tier.

## Prerequisites

- AWS account with permissions for VPC, EC2, ELBv2, ACM, Verified Access, CloudWatch, SNS, IAM, S3, SSM, and IAM Identity Center discovery.
- An **organization instance** of IAM Identity Center enabled in `us-east-1`, with users, verified primary email addresses, and the approved group already present. Terraform discovers it; it never creates or destroys it.
- Terraform `>= 1.6` or a compatible OpenTofu release. Terraform `>= 1.10` is recommended for native S3 lockfiles.
- AWS CLI v2, Node.js 20, npm, Bash, Docker for local application work, and an externally managed DNS zone for `lax-man.in`.
- GitHub repository with protected `dev`, `uat`, and `prod` promotion branches; matching GitHub Environments; repository variables; and AWS OIDC trust configured.

## Values you must provide

Copy `terraform/environments/dev/terraform.tfvars.example` to `terraform.tfvars` and replace:

- Stage-specific approved Identity Center group IDs: immutable UUIDs shown by IAM Identity Center.
- `approved_user_emails`: explicit verified Identity Center emails allowed in addition to the corporate domain.
- `alert_email`: defaults to `sammaxi416@gmail.com`; use `""` to omit the subscription.
- `state_bucket_name` in bootstrap configuration.
- `github_oidc_subject_prefix`: exact GitHub token subject prefix for your repository.
- `github_environments`: keep `dev`, `uat`, and `prod` unless GitHub Environment names are intentionally changed.

Do not commit `.tfvars`, credentials, tokens, state, private keys, or identity JWTs.

## Deployment

### 1. Bootstrap remote state and GitHub Actions OIDC

Copy the example, choose a globally unique state bucket, set
`enable_github_oidc = true`, and replace `github_oidc_subject_prefix` with the
exact subject prefix for this repository before applying:

```bash
cd terraform/bootstrap
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform apply
terraform output
```

Map the outputs to GitHub Actions repository variables:

- `state_bucket_name` -> `TF_STATE_BUCKET`
- `github_plan_role_arn` -> `AWS_PLAN_ROLE_ARN`
- `github_deploy_role_arns["dev"]` -> `DEV_DEPLOY_ROLE_ARN`
- `github_deploy_role_arns["uat"]` -> `UAT_DEPLOY_ROLE_ARN`
- `github_deploy_role_arns["prod"]` -> `PROD_DEPLOY_ROLE_ARN`

Bootstrap runs with local state by design. Secure that small state file, then configure the emitted bucket in `terraform/environments/dev/backend.tf.example` or GitHub repository variables. S3 versioning, encryption, public-access blocking, TLS-only access, and native S3 lockfiles are used. See [GitHub Actions setup](docs/github-actions.md) and [implementation](docs/implementation.md).

### 2. Phase 1: infrastructure and certificate request

The following is a Dev local example. Dev, UAT, and Prod use the same reviewed Terraform composition but independent variables, resource names, and S3 state keys. Leave `enable_verified_access = false` and initialize the partial backend with the bucket created above:

```bash
cp terraform/environments/dev/terraform.tfvars.example terraform/environments/dev/terraform.tfvars
export TF_STATE_BUCKET="the-bucket-created-by-bootstrap"
terraform -chdir=terraform/environments/dev init \
  -backend-config="bucket=$TF_STATE_BUCKET" \
  -backend-config="key=aws-verified-access-zero-trust/dev/terraform.tfstate" \
  -backend-config="region=us-east-1" \
  -backend-config="use_lockfile=true"
terraform -chdir=terraform/environments/dev apply
terraform -chdir=terraform/environments/dev output acm_dns_validation_records
```

Create the output ACM validation CNAME at the external DNS provider. Wait until ACM reports `ISSUED`. Terraform does not change external DNS and deliberately does not use `aws_acm_certificate_validation`, which would block while the record is absent.

### 3. Phase 2: Verified Access

Confirm Identity Center prerequisites, set the real group UUID and `enable_verified_access = true`, then apply again. Create the final CNAME only after `verified_access_endpoint_domain` is populated:

```text
secure.lax-man.in CNAME <verified_access_endpoint_domain>
```

Exact instructions are in [DNS records](docs/dns-records.md) and [Identity Center](docs/identity-center.md).

The three explicitly approved Gmail users must each exist in IAM Identity
Center, have a verified primary email, and be members of the group identified
by that stage's `*_APPROVED_IDENTITY_CENTER_GROUP_ID`. The email allowlist does not bypass the
separate group-membership policy.

### 4. Deploy the existing application

GitHub Actions runs `scripts/deploy-application.sh` after the protected `dev` environment approval and Terraform apply. For an authorized local operator:

```bash
AWS_REGION=us-east-1 bash scripts/deploy-application.sh
bash scripts/health-check.sh
```

The script uploads a versioned source artifact to private S3 and uses SSM Run Command—never SSH—to build and start the containers.

## GitHub Actions pipeline

The promotion path is `feature/* -> dev -> uat -> prod`. Separate [Dev](.github/workflows/dev.yml), [UAT](.github/workflows/uat.yml), and [Prod](.github/workflows/prod.yml) workflows call one reusable pipeline. Every stage has an independent state key, domain, GitHub Environment, and OIDC deployment role. See [environment strategy](docs/environments.md) and [GitHub Actions setup](docs/github-actions.md).

Create these GitHub **Actions repository variables**:

- `AWS_PLAN_ROLE_ARN` (read-only repository-scoped OIDC role used by pull requests)
- `TF_STATE_BUCKET`
- `DEV_DEPLOY_ROLE_ARN`, `UAT_DEPLOY_ROLE_ARN`, `PROD_DEPLOY_ROLE_ARN`
- `DEV_APPROVED_IDENTITY_CENTER_GROUP_ID`, `UAT_APPROVED_IDENTITY_CENTER_GROUP_ID`, `PROD_APPROVED_IDENTITY_CENTER_GROUP_ID`
- `DEV_ENABLE_VERIFIED_ACCESS`, `UAT_ENABLE_VERIFIED_ACCESS`, `PROD_ENABLE_VERIFIED_ACCESS` (`false` in phase 1, `true` in phase 2)
- `ALERT_EMAIL` (`sammaxi416@gmail.com`)

In GitHub Settings → Environments, create `dev`, `uat`, and `prod`. Restrict them to the same-named branch; require approval for UAT and Prod. No AWS access key is stored in GitHub.

## Testing

```bash
npm --prefix backend ci && npm --prefix backend test
npm --prefix frontend ci && npm --prefix frontend run build
terraform -chdir=terraform/environments/dev fmt -check -recursive
terraform -chdir=terraform/environments/dev init -backend=false
terraform -chdir=terraform/environments/dev validate
```

Identity-based ALLOW/DENY cases require real users and browser login, so they are controlled semi-automated tests. See [testing](docs/testing.md) and the case files under `tests/`.

## Monitoring and operations

- Verified Access OCSF 0.1 logs: `/aws/verified-access/lax-man-in`, 30-day configurable retention, trust context disabled.
- Alarms: unhealthy target, ALB 5XX, target 5XX, and `VerifiedAccessDeniedRequests`.
- SNS: `verified-access-security-alerts`; email remains pending until the recipient confirms it.
- Daily operations, alarm response, certificate checks, policy review, and state recovery: [operations](docs/operations.md).

## Rollback and destroy

Use `scripts/rollback.sh <bad-commit>` to create a reviewable `git revert`; it never resets a branch or destroys infrastructure. Push the revert and run the normal plan/manual apply/verify flow. Application, policy, failed-deployment, and emergency procedures are in [rollback](docs/rollback.md).

Before destroy, retain anything required from the file-backed store and empty the versioned application artifact bucket. Disable Verified Access/DNS first, review the destroy plan, then:

```bash
terraform -chdir=terraform/environments/dev plan -destroy
terraform -chdir=terraform/environments/dev destroy
```

The organization Identity Center instance and external DNS records are never destroyed by Terraform.

## Cost and security notes

Cost-generating resources include Verified Access endpoint usage, one internal ALB, one `t3.micro`, EBS, one NAT gateway plus data, CloudWatch Logs/metrics, S3 storage, and SNS email delivery. No RDS, EKS, ECS, WAF, or CloudFront is created. The NAT gateway is genuinely used for first-boot packages and Docker image pulls; set `enable_nat_gateway=false` only with a pre-baked AMI/offline artifact strategy.

The ALB is internal, EC2 has no public IP, there is no SSH rule or key pair, IMDSv2 is mandatory, EBS and S3 are encrypted, and application ingress is security-group-to-security-group only. `/identity` returns only allowlisted decoded claims and labels them unverified; do not make application authorization decisions from those claims without validating the Verified Access signature.

See [troubleshooting](docs/troubleshooting.md) for common deployment failures.
