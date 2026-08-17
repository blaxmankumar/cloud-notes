// Group IDs are immutable Identity Center identifiers; names are not used.
// Access is permitted only when the authenticated user is a member of the
// group supplied through Terraform or a protected GitHub Actions variable.
permit(principal, action, resource)
when {
  context.idc.groups has "${approved_identity_center_group_id}"
};
