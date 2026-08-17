data "aws_ssoadmin_instances" "current" {
  count = var.enabled ? 1 : 0
}

resource "aws_verifiedaccess_instance" "this" {
  count       = var.enabled ? 1 : 0
  description = "Zero Trust access for ${var.application_domain}"
  tags        = merge(var.tags, { Name = "${var.name_prefix}-verified-access" })
}

resource "aws_verifiedaccess_trust_provider" "identity_center" {
  count                    = var.enabled ? 1 : 0
  policy_reference_name    = "idc"
  trust_provider_type      = "user"
  user_trust_provider_type = "iam-identity-center"
  description              = "Regional IAM Identity Center user trust provider"
  tags                     = merge(var.tags, { Name = "${var.name_prefix}-idc" })

  lifecycle {
    precondition {
      condition     = length(data.aws_ssoadmin_instances.current[0].arns) > 0
      error_message = "IAM Identity Center must already be enabled in us-east-1 before Verified Access is enabled."
    }
  }
}

resource "aws_verifiedaccess_instance_trust_provider_attachment" "identity_center" {
  count                            = var.enabled ? 1 : 0
  verifiedaccess_instance_id       = aws_verifiedaccess_instance.this[0].id
  verifiedaccess_trust_provider_id = aws_verifiedaccess_trust_provider.identity_center[0].id
}

resource "aws_verifiedaccess_group" "this" {
  count                      = var.enabled ? 1 : 0
  verifiedaccess_instance_id = aws_verifiedaccess_instance_trust_provider_attachment.identity_center[0].verifiedaccess_instance_id
  description                = "Corporate domain gate for ${var.application_domain}"
  policy_document = templatefile(var.group_policy_path, {
    approved_email_domain      = var.approved_email_domain
    approved_user_emails_cedar = jsonencode(var.approved_user_emails)
  })
  tags = merge(var.tags, { Name = "${var.name_prefix}-group" })
}

resource "aws_verifiedaccess_endpoint" "this" {
  count                    = var.enabled ? 1 : 0
  application_domain       = var.application_domain
  attachment_type          = "vpc"
  description              = "Protected Cloud Notes application"
  domain_certificate_arn   = var.certificate_arn
  endpoint_domain_prefix   = var.endpoint_domain_prefix
  endpoint_type            = "load-balancer"
  security_group_ids       = [var.security_group_id]
  verified_access_group_id = aws_verifiedaccess_group.this[0].verifiedaccess_group_id
  policy_document = templatefile(var.endpoint_policy_path, {
    approved_identity_center_group_id = var.approved_identity_center_group_id
  })

  load_balancer_options {
    load_balancer_arn = var.alb_arn
    port              = 80
    protocol          = "http"
    subnet_ids        = var.subnet_ids
  }
  tags = merge(var.tags, { Name = "${var.name_prefix}-endpoint" })

  lifecycle {
    precondition {
      condition     = can(regex("^[0-9a-fA-F-]{36}$", var.approved_identity_center_group_id))
      error_message = "approved_identity_center_group_id must be the UUID from IAM Identity Center, not a group name."
    }
  }
}

resource "aws_verifiedaccess_instance_logging_configuration" "this" {
  count                      = var.enabled ? 1 : 0
  verifiedaccess_instance_id = aws_verifiedaccess_instance.this[0].id
  access_logs {
    include_trust_context = false
    log_version           = "ocsf-0.1"
    cloudwatch_logs {
      enabled   = true
      log_group = var.cloudwatch_log_group_name
    }
  }
}
