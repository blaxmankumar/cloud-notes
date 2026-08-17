provider "aws" { region = var.aws_region }
data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "state" {
  bucket = var.state_bucket_name
  tags   = var.tags
}

resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.state.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  bucket = aws_s3_bucket.state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "state" {
  bucket                  = aws_s3_bucket.state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "state" {
  bucket = aws_s3_bucket.state.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "DenyInsecureTransport"
      Effect    = "Deny"
      Principal = "*"
      Action    = "s3:*"
      Resource  = [aws_s3_bucket.state.arn, "${aws_s3_bucket.state.arn}/*"]
      Condition = { Bool = { "aws:SecureTransport" = "false" } }
    }]
  })
}

resource "aws_iam_openid_connect_provider" "github" {
  count          = var.enable_github_oidc && var.create_github_oidc_provider ? 1 : 0
  url            = var.github_oidc_url
  client_id_list = [var.github_oidc_audience]
  tags           = var.tags
}

locals {
  github_provider_arn = var.create_github_oidc_provider ? try(aws_iam_openid_connect_provider.github[0].arn, "") : var.existing_github_oidc_provider_arn
  github_host         = trimprefix(var.github_oidc_url, "https://")
}

resource "aws_iam_role" "github_deploy" {
  for_each = var.enable_github_oidc ? var.github_environments : toset([])
  name     = "${var.project_name}-github-${each.key}-deploy"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = local.github_provider_arn }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${local.github_host}:aud" = var.github_oidc_audience
          "${local.github_host}:sub" = "${var.github_oidc_subject_prefix}:environment:${each.key}"
        }
      }
    }]
  })
  tags = var.tags

  lifecycle {
    precondition {
      condition     = var.github_oidc_subject_prefix != "" && local.github_provider_arn != ""
      error_message = "Set github_oidc_subject_prefix and create or supply the GitHub OIDC provider ARN."
    }
  }
}

resource "aws_iam_role" "github_plan" {
  count = var.enable_github_oidc ? 1 : 0
  name  = "${var.project_name}-github-plan"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = local.github_provider_arn }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = { "${local.github_host}:aud" = var.github_oidc_audience }
        StringLike   = { "${local.github_host}:sub" = "${var.github_oidc_subject_prefix}:*" }
      }
    }]
  })
  tags = var.tags

  lifecycle {
    precondition {
      condition     = var.github_oidc_subject_prefix != "" && local.github_provider_arn != ""
      error_message = "Set github_oidc_subject_prefix and create or supply the GitHub OIDC provider ARN."
    }
  }
}

resource "aws_iam_role_policy" "github_plan" {
  count = var.enable_github_oidc ? 1 : 0
  name  = "verified-access-read-only-plan"
  role  = aws_iam_role.github_plan[0].id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "StateReadAndLock"
        Effect   = "Allow"
        Action   = ["s3:ListBucket", "s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
        Resource = [aws_s3_bucket.state.arn, "${aws_s3_bucket.state.arn}/${var.project_name}/*"]
      },
      {
        Sid      = "ReadOnlyPlan"
        Effect   = "Allow"
        Resource = "*"
        Action = [
          "acm:DescribeCertificate", "acm:ListCertificates", "acm:ListTagsForCertificate",
          "cloudwatch:DescribeAlarms", "cloudwatch:ListTagsForResource",
          "ec2:Describe*", "elasticloadbalancing:Describe*",
          "iam:Get*", "iam:List*", "logs:Describe*", "logs:ListTagsForResource",
          "s3:GetBucket*", "s3:GetEncryptionConfiguration", "s3:GetLifecycleConfiguration", "s3:GetObjectTagging", "s3:ListAllMyBuckets", "s3:ListBucket",
          "sns:Get*", "sns:List*", "sso:ListInstances", "sts:GetCallerIdentity"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy" "github_deploy" {
  for_each = var.enable_github_oidc ? var.github_environments : toset([])
  name     = "verified-access-${each.key}-deployment"
  role     = aws_iam_role.github_deploy[each.key].id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "TerraformState"
        Effect = "Allow"
        Action = ["s3:ListBucket", "s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
        Resource = [
          aws_s3_bucket.state.arn,
          "${aws_s3_bucket.state.arn}/${var.project_name}/${each.key}/*"
        ]
      },
      {
        Sid    = "DeploymentServices"
        Effect = "Allow"
        Action = [
          "acm:*", "cloudwatch:*", "ec2:*", "elasticloadbalancing:*", "logs:*", "sns:*",
          "s3:CreateBucket", "s3:Delete*", "s3:Get*", "s3:List*", "s3:Put*",
          "ssm:SendCommand", "ssm:GetCommandInvocation", "ssm:DescribeInstanceInformation",
          "sso:ListInstances", "tag:GetResources"
        ]
        Resource = "*"
      },
      {
        Sid    = "ProjectIam"
        Effect = "Allow"
        Action = [
          "iam:CreateRole", "iam:DeleteRole", "iam:GetRole", "iam:TagRole", "iam:UntagRole", "iam:PassRole",
          "iam:AttachRolePolicy", "iam:DetachRolePolicy", "iam:PutRolePolicy", "iam:GetRolePolicy", "iam:DeleteRolePolicy",
          "iam:ListRolePolicies", "iam:ListAttachedRolePolicies", "iam:ListInstanceProfilesForRole",
          "iam:CreateInstanceProfile", "iam:DeleteInstanceProfile", "iam:GetInstanceProfile", "iam:AddRoleToInstanceProfile", "iam:RemoveRoleFromInstanceProfile"
        ]
        Resource = [
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.project_name}-${each.key}-*",
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:instance-profile/${var.project_name}-${each.key}-*"
        ]
      },
      {
        Sid      = "ReadSSMManagedPolicy"
        Effect   = "Allow"
        Action   = ["iam:GetPolicy", "iam:GetPolicyVersion"]
        Resource = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
      },
      {
        Sid       = "CreateRequiredServiceLinkedRoles"
        Effect    = "Allow"
        Action    = "iam:CreateServiceLinkedRole"
        Resource  = "arn:aws:iam::*:role/aws-service-role/*"
        Condition = { StringEquals = { "iam:AWSServiceName" = ["elasticloadbalancing.amazonaws.com", "verified-access.amazonaws.com"] } }
      }
    ]
  })
}
