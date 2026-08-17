output "state_bucket_name" { value = aws_s3_bucket.state.id }
output "github_deploy_role_arns" {
  value = { for environment, role in aws_iam_role.github_deploy : environment => role.arn }
}
output "github_plan_role_arn" { value = try(aws_iam_role.github_plan[0].arn, null) }
output "github_oidc_provider_arn" { value = local.github_provider_arn }
