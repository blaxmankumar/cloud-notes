output "instance_id" { value = aws_instance.this.id }
output "private_ip" { value = aws_instance.this.private_ip }
output "iam_role_arn" { value = aws_iam_role.instance.arn }
output "artifact_bucket_name" { value = aws_s3_bucket.artifacts.id }
