variable "aws_region" {
  type    = string
  default = "us-east-1"
}
variable "project_name" {
  type    = string
  default = "aws-verified-access-zero-trust"
}
variable "state_bucket_name" {
  type        = string
  description = "Globally unique S3 bucket name for Terraform state."
}
variable "enable_github_oidc" {
  type    = bool
  default = false
}
variable "create_github_oidc_provider" {
  type    = bool
  default = true
}
variable "existing_github_oidc_provider_arn" {
  type    = string
  default = ""
}
variable "github_oidc_url" {
  type    = string
  default = "https://token.actions.githubusercontent.com"
}
variable "github_oidc_audience" {
  type    = string
  default = "sts.amazonaws.com"
}
variable "github_oidc_subject_prefix" {
  type        = string
  default     = ""
  description = "Exact GitHub OIDC prefix, for example repo:OWNER/REPO or the immutable owner/repository ID form."
}
variable "github_environments" {
  type    = set(string)
  default = ["dev", "uat", "prod"]
  validation {
    condition = length(var.github_environments) > 0 && alltrue([
      for environment in var.github_environments : can(regex("^[a-z0-9-]+$", environment))
    ])
    error_message = "github_environments must contain lowercase GitHub Environment names."
  }
}
variable "tags" {
  type = map(string)
  default = {
    Project   = "aws-verified-access-zero-trust"
    ManagedBy = "Terraform"
    Owner     = "DevOps"
  }
}
