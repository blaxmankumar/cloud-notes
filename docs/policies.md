# Cedar policies

`policies/group-policy.cedar` requires a verified email and permits either the configured corporate domain or an exact member of `approved_user_emails`. Current explicit entries are `kumarblaxman@gmail.com`, `akhilydv2710@gmail.com`, and `battulalaxmankumar314@gmail.com`.

`policies/endpoint-policy.cedar` is rendered with `approved_identity_center_group_id` and uses `context.idc.groups has "UUID"`, matching AWS's Identity Center context schema. The trust provider's policy reference name is fixed to `idc`.

Verified Access is default-deny. Group and endpoint policies are both evaluated, so an approved domain without the group, or the group without the approved domain, is denied.

Safe change process:

1. Change the relevant `.tfvars`/protected CI variable or Cedar file on a branch.
2. Commit and open a pull request.
3. Review validation, security scans, and the Terraform plan.
4. Merge, run the protected manual apply, and execute all four identity scenarios.
5. If behavior is wrong, revert the commit; never edit the live policy only in the console.

`scripts/policy-update.sh` produces a plan only. AWS's Verified Access policy assistant is useful for testing captured trust context before applying a change.
