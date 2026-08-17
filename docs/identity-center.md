# IAM Identity Center prerequisite

Terraform does not create, reset, or destroy IAM Identity Center. Before phase 2:

1. In the AWS Organizations management account, enable an **organization instance** of IAM Identity Center in `us-east-1`.
2. Ensure the deployment account can use that instance and the Terraform principal can call `sso:ListInstances`.
3. Create or synchronize required users and the approved group.
4. Ensure each approved user has a verified primary email matching the corporate-domain rule or explicit email allowlist.
5. Copy the group's immutable ID/UUID—not its display name—into `approved_identity_center_group_id`.
6. Assign users to that group and test one approved and two denied identities.

The `aws_ssoadmin_instances` data source discovers regional instance ARNs and identity-store IDs. A resource precondition stops trust-provider creation when discovery returns nothing. AWS APIs do not expose a safe Terraform workflow for converting or recreating an organization's existing Identity Center instance; organization enablement and directory/group lifecycle remain prerequisites.

If trust-provider creation fails, confirm the selected console region says N. Virginia, verify the instance type, use the correct organization/delegated-admin account, and check `ec2:CreateVerifiedAccessTrustProvider` plus `sso:ListInstances` permissions.
