# GitHub Actions setup

Dev, UAT, and Prod have separate entry workflows. They call one reusable
deployment workflow so tests and security controls cannot drift between stages.
AWS access uses short-lived GitHub OIDC credentials; no AWS access keys are
stored in GitHub.

## 1. Bootstrap AWS trust

Copy `terraform/bootstrap/terraform.tfvars.example` to `terraform.tfvars`, then
set:

```hcl
enable_github_oidc         = true
github_oidc_subject_prefix = "repo:blaxmankumar/cloud-notes"
github_environments        = ["dev", "uat", "prod"]
```

Use the exact subject prefix issued for the repository. Repositories using
GitHub immutable OIDC subjects must use the owner and repository ID form shown
in their token claims instead of the legacy `repo:OWNER/REPOSITORY` form.

Run `terraform init`, `terraform plan`, and `terraform apply` from
`terraform/bootstrap`. The outputs include one plan role and a map containing
the Dev, UAT, and Prod deployment role ARNs. Keep the bootstrap local state
protected.

If the AWS account already has the GitHub Actions OIDC provider, set
`create_github_oidc_provider = false` and supply its ARN through
`existing_github_oidc_provider_arn`.

## 2. Configure repository variables

In **Settings -> Secrets and variables -> Actions -> Variables**, add:

| Variable | Value |
| --- | --- |
| `TF_STATE_BUCKET` | Bootstrap output `state_bucket_name` |
| `AWS_PLAN_ROLE_ARN` | Bootstrap output `github_plan_role_arn` |
| `DEV_DEPLOY_ROLE_ARN` | `github_deploy_role_arns["dev"]` |
| `UAT_DEPLOY_ROLE_ARN` | `github_deploy_role_arns["uat"]` |
| `PROD_DEPLOY_ROLE_ARN` | `github_deploy_role_arns["prod"]` |
| `DEV_APPROVED_IDENTITY_CENTER_GROUP_ID` | Dev group UUID |
| `UAT_APPROVED_IDENTITY_CENTER_GROUP_ID` | UAT group UUID |
| `PROD_APPROVED_IDENTITY_CENTER_GROUP_ID` | Production group UUID |
| `DEV_ENABLE_VERIFIED_ACCESS` | Start with `false` |
| `UAT_ENABLE_VERIFIED_ACCESS` | Start with `false` |
| `PROD_ENABLE_VERIFIED_ACCESS` | Start with `false` |
| `ALERT_EMAIL` | `sammaxi416@gmail.com` |

OIDC role ARNs, state bucket names, and group UUIDs are identifiers rather than
passwords, so repository variables are appropriate. Never store AWS access keys
or Terraform state in GitHub variables.

## 3. Create protected GitHub Environments

In **Settings -> Environments**, create:

- `dev`: deployment branch `develop`; reviewer optional.
- `uat`: deployment branch `uat`; at least one required reviewer.
- `prod`: deployment branch `main`; required reviewer and the strictest wait or
  approval rules available to the repository.

The matching AWS role trusts only its GitHub Environment OIDC subject. Plan runs
with the read-only plan role before the deployment approval. Apply, application
deployment, and verification run together in one approved environment job.

## 4. Configure branch protection

Create `develop` and `uat`, then protect `develop`, `uat`, and `main`. Require a
pull request, prevent force pushes, and require the matching workflow checks.
Use the promotion sequence documented in [environments](environments.md).

## 5. Deploy each stage in two phases

For each stage independently:

1. Keep its `*_ENABLE_VERIFIED_ACCESS` variable `false` and merge to the stage
   branch. Terraform creates the base infrastructure and certificate request.
2. Publish that stage's ACM validation CNAME and wait for `ISSUED`.
3. Verify the correct Identity Center group and users.
4. Change its `*_ENABLE_VERIFIED_ACCESS` variable to `true` and rerun the stage
   workflow.
5. Publish the stage application CNAME to its
   `verified_access_endpoint_domain` output.
6. Confirm each SNS subscription email sent to `sammaxi416@gmail.com`.

Feature pushes run the Dev checks. If the OIDC variables are not configured yet,
tests and security checks run while the Terraform plan is skipped.
