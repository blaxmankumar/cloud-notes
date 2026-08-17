# Dev, UAT, and production environments

The repository uses one Terraform composition and shared modules for all three
environments. The workflow supplies the environment name, domain, and state key,
so infrastructure code stays identical while state and AWS resources remain
separate.

| Stage | Promotion branch | GitHub workflow | Domain | Terraform state key |
| --- | --- | --- | --- | --- |
| Dev | `dev` | `dev.yml` | `secure-dev.lax-man.in` | `aws-verified-access-zero-trust/dev/terraform.tfstate` |
| UAT | `uat` | `uat.yml` | `secure-uat.lax-man.in` | `aws-verified-access-zero-trust/uat/terraform.tfstate` |
| Prod | `prod` | `prod.yml` | `secure.lax-man.in` | `aws-verified-access-zero-trust/prod/terraform.tfstate` |

The three stage workflows call `_environment-deploy.yml`. That reusable
workflow contains the common validation, tests, security scans, Terraform plan,
approved apply, SSM application deployment, and health verification. This gives
each stage an independent trigger without copying the deployment logic.

## Promotion model

```text
feature/* --pull request--> dev --pull request--> uat --pull request--> prod
                              Dev                       UAT                    Prod
```

1. Work only on a `feature/*` branch. A feature push and a pull request to
   `dev` validate and plan Dev but never apply.
2. Merging into `dev` deploys Dev.
3. Open a pull request from `dev` to `uat`. Merging deploys UAT after the
   `uat` GitHub Environment approval.
4. After UAT acceptance, open a pull request from `uat` to `prod`. Merging
   deploys production after the `prod` GitHub Environment approval.

Do not merge feature branches directly into `uat` or `prod`. Protect all three
promotion branches and require the matching workflow checks.

## Isolation model

- Separate S3 state object and lock file per stage.
- Resource names and tags contain `dev`, `uat`, or `prod`.
- Separate VPC, ALB, EC2 instance, certificate, Verified Access endpoint, logs,
  alarms, and application artifact bucket per stage.
- Separate GitHub OIDC deployment role per GitHub Environment.
- One read-only repository-scoped plan role.

The same explicit email allowlist is used by default in every stage. Use a
different immutable IAM Identity Center group UUID for each stage if possible.
Every allowed user still needs both a verified email and membership in the
stage's approved group.

## Local environment plan

Copy only the environment you need; generated `.tfvars` files are ignored by
Git:

```bash
cp terraform/environments/config/dev.tfvars.example terraform/environments/config/dev.tfvars
ENVIRONMENT=dev TF_STATE_BUCKET=your-state-bucket bash scripts/deploy.sh
```

Replace `dev` with `uat` or `prod`. Always review the selected environment and
state key in the Terraform output before typing `APPLY`.
