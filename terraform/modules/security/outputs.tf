output "verified_access_security_group_id" { value = aws_security_group.verified_access.id }
output "alb_security_group_id" { value = aws_security_group.alb.id }
output "app_security_group_id" { value = aws_security_group.app.id }
