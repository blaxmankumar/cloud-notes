# Single main environment

The learning setup intentionally has one environment named `main`.

| Environment | Branch | Workflow | Domain | Terraform state key |
| --- | --- | --- | --- | --- |
| Main | `main` | `main.yml` | `secure.lax-man.in` | `aws-verified-access-zero-trust/main/terraform.tfstate` |

The entry workflow calls `_environment-deploy.yml`, which contains validation,
tests, security scans, Terraform plan, approved apply, SSM application
deployment, and health verification.

## Simple learning flow

```text
feature/* --pull request--> main --environment approval--> AWS
```

Feature pushes and pull requests validate and plan but never apply. Merging to
`main` runs a new plan and waits for approval on the GitHub `main` Environment
before making AWS changes.

## Isolation

- One S3 state object and lock file.
- One GitHub OIDC deployment role for the `main` Environment.
- One VPC, ALB, EC2 instance, certificate, Verified Access endpoint, log group,
  alarm set, and artifact bucket.

The email allowlist still requires each user to have a verified IAM Identity
Center email and membership in the approved group.

## Local plan

Copy the example; generated `.tfvars` files are ignored by Git:

```bash
cp terraform/environments/config/main.tfvars.example terraform/environments/config/main.tfvars
ENVIRONMENT=main TF_STATE_BUCKET=your-state-bucket bash scripts/deploy.sh
```

Always confirm the environment and state key before approving a Terraform
apply.
