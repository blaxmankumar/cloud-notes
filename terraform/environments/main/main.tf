locals {
  name_prefix = "${var.project_name}-${var.environment}"
  common_tags = merge({
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Owner       = "DevOps"
  }, var.additional_tags)
}

module "network" {
  source               = "../../modules/network"
  name_prefix          = local.name_prefix
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  enable_nat_gateway   = var.free_tier_mode ? false : var.enable_nat_gateway
  tags                 = local.common_tags
}

module "security" {
  source           = "../../modules/security"
  name_prefix      = local.name_prefix
  vpc_id           = module.network.vpc_id
  vpc_cidr         = module.network.vpc_cidr
  application_port = var.application_port
  free_tier_mode   = var.free_tier_mode
  tags             = local.common_tags
}

module "ec2" {
  source                      = "../../modules/ec2"
  name_prefix                 = local.name_prefix
  subnet_id                   = var.free_tier_mode ? module.network.public_subnet_ids[0] : module.network.private_subnet_ids[0]
  security_group_id           = module.security.app_security_group_id
  instance_type               = var.instance_type
  root_volume_size            = var.root_volume_size
  associate_public_ip_address = var.free_tier_mode
  enable_detailed_monitoring  = false
  artifact_bucket_name        = "${var.project_name}-${var.environment}-${data.aws_caller_identity.current.account_id}-artifacts"
  tags                        = local.common_tags
}

module "alb" {
  count             = var.free_tier_mode ? 0 : 1
  source            = "../../modules/alb"
  name_prefix       = local.name_prefix
  vpc_id            = module.network.vpc_id
  subnet_ids        = module.network.private_subnet_ids
  security_group_id = module.security.alb_security_group_id
  instance_id       = module.ec2.instance_id
  application_port  = var.application_port
  tags              = local.common_tags
}

module "acm" {
  count              = var.free_tier_mode ? 0 : 1
  source             = "../../modules/acm"
  application_domain = var.application_domain
  tags               = local.common_tags
}

module "monitoring" {
  source                            = "../../modules/monitoring"
  name_prefix                       = local.name_prefix
  log_group_name                    = "/aws/verified-access/lax-man-in"
  log_retention_days                = var.log_retention_days
  alb_arn_suffix                    = try(module.alb[0].arn_suffix, "")
  target_group_arn_suffix           = try(module.alb[0].target_group_arn_suffix, "")
  alert_email                       = var.alert_email
  denied_request_threshold          = var.denied_request_threshold
  alb_5xx_threshold                 = var.alb_5xx_threshold
  target_5xx_threshold              = var.target_5xx_threshold
  instance_id                       = module.ec2.instance_id
  enable_ec2_alarm                  = true
  enable_alb_alarms                 = !var.free_tier_mode
  enable_verified_access_monitoring = !var.free_tier_mode && var.enable_verified_access
  tags                              = local.common_tags
}

module "verified_access" {
  count                             = var.free_tier_mode ? 0 : 1
  source                            = "../../modules/verified-access"
  enabled                           = var.enable_verified_access
  name_prefix                       = local.name_prefix
  application_domain                = var.application_domain
  endpoint_domain_prefix            = var.endpoint_domain_prefix
  certificate_arn                   = module.acm[0].certificate_arn
  alb_arn                           = module.alb[0].arn
  subnet_ids                        = module.network.private_subnet_ids
  security_group_id                 = module.security.verified_access_security_group_id
  approved_email_domain             = var.approved_email_domain
  approved_user_emails              = var.approved_user_emails
  approved_identity_center_group_id = var.approved_identity_center_group_id
  group_policy_path                 = "${path.root}/../../../policies/group-policy.cedar"
  endpoint_policy_path              = "${path.root}/../../../policies/endpoint-policy.cedar"
  cloudwatch_log_group_name         = module.monitoring.log_group_name
  tags                              = local.common_tags
}

check "verified_access_inputs" {
  assert {
    condition     = var.free_tier_mode || !var.enable_verified_access || (var.approved_identity_center_group_id != "" && var.approved_identity_center_group_id != "REPLACE_ME")
    error_message = "Set approved_identity_center_group_id before enabling Verified Access."
  }
}

check "free_tier_controls" {
  assert {
    condition = !var.free_tier_mode || (
      !var.enable_nat_gateway &&
      !var.enable_verified_access &&
      var.instance_type == "t3.micro"
    )
    error_message = "Free Tier mode requires t3.micro with NAT Gateway and Verified Access disabled."
  }
}
