# Implementation and state

Terraform is split into `network`, `security`, `ec2`, `alb`, `acm`, `verified-access`, and `monitoring` modules. The shared composition under `terraform/environments/dev` is parameterized as Dev, UAT, or Prod by its workflow; each stage uses a different state key and environment-tagged resources. Optional state/OIDC bootstrap is separate so the state bucket is never created by the configuration that depends on it.

The S3 backend uses encryption, versioning, public-access blocking, TLS-only access, and Terraform's current `use_lockfile = true` conditional-write locking. Native lockfiles require Terraform 1.10 or later; teams pinned to 1.6–1.9 must upgrade or deliberately add legacy DynamoDB locking. OpenTofu users should verify support in their selected release.

ACM is a two-phase operation because DNS is external:

1. `enable_verified_access=false` creates the certificate request and all backend infrastructure.
2. Create the validation CNAME and wait for `ISSUED`.
3. Set a real group UUID and `enable_verified_access=true`; apply creates trust, group, endpoint, and logging.
4. Create the final application CNAME.

Application deployment packages the existing source, uploads it to the versioned private S3 bucket, and invokes SSM Run Command. EC2 builds the pinned package-lock dependencies and starts the standalone AWS Compose file. SSM replaces SSH and there is no key pair.

The optional bootstrap creates one repository-scoped plan role and separate Dev, UAT, and Prod deployment roles. The plan role is read-only except for state lock objects, so pull requests can refresh and plan without infrastructure mutation authority. Each deployment role trusts only its matching GitHub Environment subject and is not AdministratorAccess. Its deployment service actions are broad because many EC2/Verified Access APIs do not support useful resource scoping; IAM role/profile operations are restricted to the matching project and stage prefix.

GitHub changed new-repository OIDC subjects to an immutable owner/repository ID format in July 2026. Set `github_oidc_subject_prefix` to the exact prefix used by your repository token: either `repo:OWNER/REPO` for legacy format or `repo:OWNER@OWNER_ID/REPO@REPOSITORY_ID` for immutable format.
