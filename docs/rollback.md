# Rollback

## Normal configuration or policy rollback

```bash
git log --oneline
bash scripts/rollback.sh <bad-commit-sha>
git show --stat
git push origin main
```

The script requires a clean tree, verifies the commit is an ancestor, asks for `REVERT`, and creates a normal revert commit. GitHub Actions then validates, plans, waits for protected-environment approval, applies, redeploys if needed, and verifies. It never runs `reset --hard`, force-pushes, destroys resources, or bypasses review.

## Application rollback

Revert the application commit and run the pipeline. S3 artifact versioning retains earlier bundles, but redeploying from a known Git commit is preferred because it is auditable. For an urgent operational restore, upload the known-good commit artifact and invoke the same SSM procedure; follow with a Git revert so desired state matches reality.

## Failed Terraform apply

Do not re-run blindly. Read the error and state, refresh/plan, and determine whether AWS created a resource. Import an orphan when appropriate; do not delete organization Identity Center or external DNS. Use S3 state version history only for true state corruption, with exclusive access and a preserved copy.

## Emergency access recovery

Verified Access is fail closed. Revert the bad Cedar change. If the pipeline role cannot apply, an authorized break-glass operator may run the reviewed Terraform plan locally with MFA. Never expose the ALB/EC2 publicly as a workaround. Console edits are last resort and must immediately be reconciled into Git/Terraform.

## Data and infrastructure rollback

The file store lives in the Docker volume on encrypted root EBS. Snapshot before disruptive host replacement. Terraform configuration rollback changes infrastructure forward to the previous definition; Terraform has no transactional infrastructure rollback. Review replacements carefully, especially EC2 and its root volume.
