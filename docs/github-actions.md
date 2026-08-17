# GitHub Actions setup

The learning setup has one `main` environment. Feature branches validate and
plan; only the `main` branch can deploy. AWS access uses short-lived GitHub OIDC
credentials, so no AWS access keys are stored in GitHub.

## Bootstrap trust

The bootstrap variables are:

```hcl
enable_github_oidc         = true
github_oidc_subject_prefix = "repo:blaxmankumar/cloud-notes"
github_environments        = ["main"]
```

Bootstrap outputs one repository plan role and one `main` deployment role. If
the account already has the GitHub OIDC provider, reuse its ARN instead of
creating another provider.

## Repository variables

In **Settings -> Secrets and variables -> Actions -> Variables**, keep:

| Variable | Value |
| --- | --- |
| `TF_STATE_BUCKET` | `newtarzan-038832652205-terraform-state` |
| `AWS_PLAN_ROLE_ARN` | Bootstrap output `github_plan_role_arn` |
| `MAIN_DEPLOY_ROLE_ARN` | `github_deploy_role_arns["main"]` |
| `MAIN_APPROVED_IDENTITY_CENTER_GROUP_ID` | Immutable Identity Center group UUID |
| `MAIN_ENABLE_VERIFIED_ACCESS` | Start with `false` |
| `ALERT_EMAIL` | `sammaxi416@gmail.com` |

The old `DEV_*`, `UAT_*`, and `PROD_*` repository variables are no longer used
and may be deleted after the simplified bootstrap apply succeeds.

## Protected GitHub Environment

Create one GitHub Environment named `main`. Restrict its deployment branch to
`main` and configure a required reviewer when the repository plan supports it.
The AWS deployment role trusts only this exact environment subject:

```text
repo:blaxmankumar/cloud-notes:environment:main
```

## Two deployment phases

1. Keep `MAIN_ENABLE_VERIFIED_ACCESS=false` and merge to `main` to create the
   base infrastructure and ACM certificate request.
2. Publish the ACM validation CNAME and wait for `ISSUED`.
3. Verify the Identity Center group and users.
4. Change `MAIN_ENABLE_VERIFIED_ACCESS=true` and rerun the workflow.
5. Publish `secure.lax-man.in` as a CNAME to the
   `verified_access_endpoint_domain` output.
6. Confirm the SNS subscription sent to `sammaxi416@gmail.com`.
