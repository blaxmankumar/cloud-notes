output "vpc_id" { value = module.network.vpc_id }
output "private_subnet_ids" { value = module.network.private_subnet_ids }
output "alb_arn" { value = module.alb.arn }
output "alb_dns_name" { value = module.alb.dns_name }
output "ec2_instance_id" { value = module.ec2.instance_id }
output "application_artifact_bucket" { value = module.ec2.artifact_bucket_name }
output "verified_access_instance_id" { value = module.verified_access.instance_id }
output "verified_access_group_id" { value = module.verified_access.group_id }
output "verified_access_endpoint_id" { value = module.verified_access.endpoint_id }
output "verified_access_endpoint_domain" { value = module.verified_access.endpoint_domain }
output "acm_certificate_arn" { value = module.acm.certificate_arn }
output "acm_certificate_status" { value = module.acm.status }
output "acm_dns_validation_records" { value = module.acm.dns_validation_records }
output "required_application_dns_record" {
  value = {
    name  = var.application_domain
    type  = "CNAME"
    value = module.verified_access.endpoint_domain
  }
}
output "cloudwatch_log_group" { value = module.monitoring.log_group_name }
output "sns_topic_arn" { value = module.monitoring.sns_topic_arn }
output "application_url" { value = "https://${var.application_domain}" }
output "identity_center_instance_arns" { value = module.verified_access.identity_center_instance_arns }
output "deployment_phase" {
  value = var.enable_verified_access ? "Phase 2: Verified Access enabled; create the application CNAME after endpoint creation." : "Phase 1: create ACM validation CNAME, wait for ISSUED, then set enable_verified_access=true."
}
