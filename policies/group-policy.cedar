// Allow only IAM Identity Center users whose primary email is verified.
// Access is granted to the configured corporate domain OR an explicitly
// approved full email address. Endpoint policy group membership is still required.
permit(principal, action, resource)
when {
  context.idc.user.email.verified == true
  && (
    context.idc.user.email.address like "*@${approved_email_domain}"
    || ${approved_user_emails_cedar}.contains(context.idc.user.email.address)
  )
};
