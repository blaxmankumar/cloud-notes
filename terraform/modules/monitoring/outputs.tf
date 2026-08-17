output "log_group_name" { value = try(aws_cloudwatch_log_group.verified_access[0].name, null) }
output "log_group_arn" { value = try(aws_cloudwatch_log_group.verified_access[0].arn, null) }
output "sns_topic_arn" { value = aws_sns_topic.alerts.arn }
