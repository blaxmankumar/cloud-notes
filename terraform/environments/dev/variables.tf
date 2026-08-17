variable "aws_region" {
  type    = string
  default = "us-east-1"
  validation {
    condition     = var.aws_region == "us-east-1"
    error_message = "This implementation is intentionally restricted to us-east-1."
  }
}
variable "environment" {
  type    = string
  default = "dev"
}
variable "project_name" {
  type    = string
  default = "aws-verified-access-zero-trust"
}
variable "application_domain" {
  type    = string
  default = "secure.lax-man.in"
}
variable "base_domain" {
  type    = string
  default = "lax-man.in"
}
variable "approved_email_domain" {
  type    = string
  default = "magnitglobal.com"
  validation {
    condition     = can(regex("^[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?(?:\\.[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?)+$", var.approved_email_domain))
    error_message = "approved_email_domain must be a lowercase DNS domain without @ or wildcards."
  }
}
variable "approved_user_emails" {
  type = list(string)
  default = [
    "kumarblaxman@gmail.com",
    "akhilydv2710@gmail.com",
    "battulalaxmankumar314@gmail.com"
  ]
  validation {
    condition = length(var.approved_user_emails) > 0 && alltrue([
      for email in var.approved_user_emails : can(regex("^[^@[:space:]]+@[^@[:space:]]+\\.[^@[:space:]]+$", email))
    ])
    error_message = "Every approved_user_emails value must be a valid email address."
  }
}
variable "approved_identity_center_group_id" {
  type        = string
  default     = ""
  description = "IAM Identity Center immutable group UUID; required when enable_verified_access is true."
}
variable "alert_email" {
  type    = string
  default = "sammaxi416@gmail.com"
  validation {
    condition     = var.alert_email == "" || can(regex("^[^@[:space:]]+@[^@[:space:]]+\\.[^@[:space:]]+$", var.alert_email))
    error_message = "alert_email must be blank or a valid email address."
  }
}
variable "endpoint_domain_prefix" {
  type    = string
  default = "lax-man-secure"
  validation {
    condition     = can(regex("^[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?$", var.endpoint_domain_prefix))
    error_message = "endpoint_domain_prefix must be a lowercase DNS label."
  }
}
variable "enable_verified_access" {
  type        = bool
  default     = false
  description = "Phase-two switch. Enable only after ACM reports ISSUED and Identity Center prerequisites are complete."
}
variable "enable_nat_gateway" {
  type        = bool
  default     = true
  description = "Provides private instance egress for bootstrapping and Docker builds; disable only with a pre-baked/offline deployment path."
}
variable "vpc_cidr" {
  type    = string
  default = "10.20.0.0/16"
}
variable "public_subnet_cidrs" {
  type    = list(string)
  default = ["10.20.1.0/24", "10.20.2.0/24"]
}
variable "private_subnet_cidrs" {
  type    = list(string)
  default = ["10.20.11.0/24", "10.20.12.0/24"]
}
variable "application_port" {
  type    = number
  default = 8000
}
variable "instance_type" {
  type    = string
  default = "t3.micro"
}
variable "root_volume_size" {
  type    = number
  default = 16
}
variable "log_retention_days" {
  type    = number
  default = 30
}
variable "denied_request_threshold" {
  type    = number
  default = 5
}
variable "alb_5xx_threshold" {
  type    = number
  default = 5
}
variable "target_5xx_threshold" {
  type    = number
  default = 5
}
variable "additional_tags" {
  type    = map(string)
  default = {}
}
