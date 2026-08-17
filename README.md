# Cloud Notes on AWS Free Tier

Single-environment AWS learning project for the existing React/Node Cloud Notes application. The default deployment is tuned for this account's Free Tier credit window: one `t3.micro`, a small encrypted EBS volume, private S3 artifacts, SSM deployment, CloudWatch status alarm, and SNS email alerts.

Free Tier mode deliberately does not create a NAT Gateway, Application Load Balancer, ACM certificate, or AWS Verified Access endpoint. These services have hourly charges that can consume Free Tier credits quickly. The application is reachable on the EC2 public address at port `8000`; SSH is not exposed and administration uses SSM.

## Architecture

```text
User -> EC2 public address:8000 -> React/Nginx -> Node API
GitHub Actions -> AWS OIDC -> S3 artifact -> SSM Run Command -> EC2
```

An EC2 status-check alarm notifies an SNS topic, and GitHub Actions deploys through short-lived AWS OIDC credentials. The production Verified Access modules remain available for later study but are disabled by `free_tier_mode = true`. See [architecture](docs/architecture.md).

## Important application choice

This repository started as the supplied React/Node Cloud Notes application, so it intentionally uses that application instead of replacing it with the Flask sample mentioned in the baseline. AWS deployment defaults to a file-backed note store on the encrypted EC2 EBS volume, avoiding RDS cost. The original MySQL mode remains available with `DB_MODE=mysql` and the `DB_*` settings. The single-instance file store is suitable for this demo, not a horizontally scaled production data tier.

## Prerequisites

- AWS account with permissions for VPC, EC2, CloudWatch, SNS, IAM, S3, and SSM. ELBv2, ACM, Verified Access, and IAM Identity Center are needed only if the paid production path is enabled later.
- Terraform `>= 1.6` or a compatible OpenTofu release. Terraform `>= 1.10` is recommended for native S3 lockfiles.
- AWS CLI v2, Node.js 20, npm, Bash, and Docker for local application work.
- GitHub repository with protected `main`, a matching `main` GitHub Environment, repository variables, and AWS OIDC trust configured.

## Values you must provide

Copy `terraform/environments/main/terraform.tfvars.example` to `terraform.tfvars` and replace:

- Keep `free_tier_mode = true`, `enable_nat_gateway = false`, and `enable_verified_access = false`.
- `approved_user_emails` remains recorded for the later Verified Access phase; it is not an authentication mechanism in public Free Tier mode.
- `alert_email`: defaults to `sammaxi416@gmail.com`; use `""` to omit the subscription.
- `state_bucket_name` in bootstrap configuration.
- `github_oidc_subject_prefix`: exact GitHub token subject prefix for your repository.
- `github_environments`: keep `["main"]` for this learning setup.

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
- `github_deploy_role_arns["main"]` -> `MAIN_DEPLOY_ROLE_ARN`

Bootstrap runs with local state by design. Secure that small state file, then configure the emitted bucket in `terraform/environments/main/backend.tf.example` or GitHub repository variables. S3 versioning, encryption, public-access blocking, TLS-only access, and native S3 lockfiles are used. See [GitHub Actions setup](docs/github-actions.md) and [implementation](docs/implementation.md).

### 2. Deploy the Free Tier learning infrastructure

Keep `free_tier_mode = true`, `enable_nat_gateway = false`, and `enable_verified_access = false`, then initialize the main backend:

```bash
cp terraform/environments/main/terraform.tfvars.example terraform/environments/main/terraform.tfvars
export TF_STATE_BUCKET="the-bucket-created-by-bootstrap"
terraform -chdir=terraform/environments/main init \
  -backend-config="bucket=$TF_STATE_BUCKET" \
  -backend-config="key=aws-verified-access-zero-trust/main/terraform.tfstate" \
  -backend-config="region=us-east-1" \
  -backend-config="use_lockfile=true"
terraform -chdir=terraform/environments/main apply
terraform -chdir=terraform/environments/main output application_url
```

The output URL uses the instance's public IPv4 address and port `8000`. The address may change after an EC2 stop/start. Do not enable NAT, ALB, or Verified Access while the goal is to minimize credit usage.

### 3. Optional paid production phase

After the learning phase, set `free_tier_mode = false` only after reviewing an AWS cost estimate. The production path can then use ACM, an internal ALB, IAM Identity Center, and Verified Access.

```text
secure.lax-man.in CNAME <verified_access_endpoint_domain>
```

Exact instructions are in [DNS records](docs/dns-records.md) and [Identity Center](docs/identity-center.md).

The three explicitly approved Gmail users must exist in IAM Identity Center before the paid Verified Access path can enforce the allowlist. Free Tier mode does not claim to authenticate an email address.

### 4. Deploy the existing application

GitHub Actions runs `scripts/deploy-application.sh` after the protected `main` environment approval and Terraform apply. For an authorized local operator:

```bash
AWS_REGION=us-east-1 bash scripts/deploy-application.sh
bash scripts/health-check.sh
```

The script uploads a short-lived versioned source artifact to private S3 and uses SSM Run Command—never SSH—to build and start the containers.

## GitHub Actions pipeline

The learning path is `feature/* -> main`. The [Main workflow](.github/workflows/main.yml) calls one reusable pipeline for validation, tests, security scans, plan, approved apply, deployment, and verification. See [environment strategy](docs/environments.md) and [GitHub Actions setup](docs/github-actions.md).

Create these GitHub **Actions repository variables**:

- `AWS_PLAN_ROLE_ARN` (read-only repository-scoped OIDC role used by pull requests)
- `TF_STATE_BUCKET`
- `MAIN_DEPLOY_ROLE_ARN`
- `MAIN_ENABLE_VERIFIED_ACCESS` (`false` while Free Tier mode is active)
- `ALERT_EMAIL` (`sammaxi416@gmail.com`)

In GitHub Settings → Environments, create `main`, restrict it to the `main` branch, and add a reviewer when supported. No AWS access key is stored in GitHub.

## Testing

```bash
npm --prefix backend ci && npm --prefix backend test
npm --prefix frontend ci && npm --prefix frontend run build
terraform -chdir=terraform/environments/main fmt -check -recursive
terraform -chdir=terraform/environments/main init -backend=false
terraform -chdir=terraform/environments/main validate
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
terraform -chdir=terraform/environments/main plan -destroy
terraform -chdir=terraform/environments/main destroy
```

The organization Identity Center instance and external DNS records are never destroyed by Terraform.

## Cost and security notes

Cost-generating resources include Verified Access endpoint usage, one internal ALB, one `t3.micro`, EBS, one NAT gateway plus data, CloudWatch Logs/metrics, S3 storage, and SNS email delivery. No RDS, EKS, ECS, WAF, or CloudFront is created. The NAT gateway is genuinely used for first-boot packages and Docker image pulls; set `enable_nat_gateway=false` only with a pre-baked AMI/offline artifact strategy.

The ALB is internal, EC2 has no public IP, there is no SSH rule or key pair, IMDSv2 is mandatory, EBS and S3 are encrypted, and application ingress is security-group-to-security-group only. `/identity` returns only allowlisted decoded claims and labels them unverified; do not make application authorization decisions from those claims without validating the Verified Access signature.

See [troubleshooting](docs/troubleshooting.md) for common deployment failures.
