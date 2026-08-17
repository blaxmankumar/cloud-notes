# Testing

## Automated checks

Run `scripts/validate.sh` on Linux, or run the README commands individually. Backend tests cover health, safe identity inspection, validation, and note CRUD. The frontend production build catches JSX/bundling errors. Terraform formatting/validation and Cedar guard checks run in GitHub Actions. Checkov scans IaC; Trivy scans secrets and misconfiguration.

After deployment, `scripts/health-check.sh` checks ELB target health through AWS APIs. `scripts/access-test.sh` checks HTTP boundary behavior but cannot automate interactive Identity Center credentials.

## Required access matrix

| Test | Identity | Expected |
|---|---|---|
| Approved | any configured corporate-domain or explicit allowlist email, approved group | Identity Center login, then HTTP 200 |
| Invalid domain | `user@gmail.com`, even if otherwise known | DENY; no application request log |
| Invalid group | approved Gmail address, removed from approved group | DENY; no application request log |
| Unauthenticated | no session | redirect to Identity Center or deny |
| Health | ALB target-health API | `healthy`; backend `/health` returns 200 JSON |
| Direct ALB | public DNS/network | impossible: internal scheme and SG source restriction |
| Direct EC2 | public DNS/network | impossible: no public IP and SG source restriction |

For deny cases, correlate a new OCSF denial in CloudWatch with the attempt time and confirm the Node request log did not record the path. Do not share cookies or JWTs between testers.

## Policy change demonstration

Temporarily propose a different approved group in a branch, or change one test allowlist address. The pull-request plan must show only the Verified Access policy update. After protected-environment approval and apply, rerun the matrix, then use `git revert` and the same controlled workflow to restore the original policy.
