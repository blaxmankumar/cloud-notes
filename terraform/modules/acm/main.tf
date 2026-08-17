resource "aws_acm_certificate" "this" {
  domain_name       = var.application_domain
  validation_method = "DNS"
  key_algorithm     = "RSA_2048"
  tags              = merge(var.tags, { Name = var.application_domain })

  lifecycle {
    create_before_destroy = true
  }
}
