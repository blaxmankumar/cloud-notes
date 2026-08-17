output "verified_access_security_group_id" { value = try(aws_security_group.verified_access[0].id, null) }
output "alb_security_group_id" { value = try(aws_security_group.alb[0].id, null) }
output "app_security_group_id" { value = aws_security_group.app.id }
