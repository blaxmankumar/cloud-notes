output "log_group_name" { value = aws_cloudwatch_log_group.verified_access.name }
output "log_group_arn" { value = aws_cloudwatch_log_group.verified_access.arn }
output "sns_topic_arn" { value = aws_sns_topic.alerts.arn }
