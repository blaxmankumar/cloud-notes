output "certificate_arn" { value = aws_acm_certificate.this.arn }
output "status" { value = aws_acm_certificate.this.status }
output "dns_validation_records" {
  value = [for option in aws_acm_certificate.this.domain_validation_options : {
    name  = option.resource_record_name
    type  = option.resource_record_type
    value = option.resource_record_value
  }]
}
