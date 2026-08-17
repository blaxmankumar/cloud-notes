output "vpc_id" { value = module.network.vpc_id }
output "private_subnet_ids" { value = module.network.private_subnet_ids }
output "alb_arn" { value = try(module.alb[0].arn, null) }
output "alb_dns_name" { value = try(module.alb[0].dns_name, null) }
output "ec2_instance_id" { value = module.ec2.instance_id }
output "ec2_public_ip" { value = module.ec2.public_ip }
output "application_artifact_bucket" { value = module.ec2.artifact_bucket_name }
output "verified_access_instance_id" { value = try(module.verified_access[0].instance_id, null) }
output "verified_access_group_id" { value = try(module.verified_access[0].group_id, null) }
output "verified_access_endpoint_id" { value = try(module.verified_access[0].endpoint_id, null) }
output "verified_access_endpoint_domain" { value = try(module.verified_access[0].endpoint_domain, null) }
output "acm_certificate_arn" { value = try(module.acm[0].certificate_arn, null) }
output "acm_certificate_status" { value = try(module.acm[0].status, null) }
output "acm_dns_validation_records" { value = try(module.acm[0].dns_validation_records, []) }
output "required_application_dns_record" {
  value = {
    name  = var.application_domain
    type  = "CNAME"
    value = try(module.verified_access[0].endpoint_domain, null)
  }
}
output "cloudwatch_log_group" { value = module.monitoring.log_group_name }
output "sns_topic_arn" { value = module.monitoring.sns_topic_arn }
output "application_url" { value = var.free_tier_mode ? "http://${module.ec2.public_ip}:${var.application_port}" : "https://${var.application_domain}" }
output "identity_center_instance_arns" { value = try(module.verified_access[0].identity_center_instance_arns, []) }
output "deployment_phase" {
  value = var.free_tier_mode ? "Free Tier learning mode: public EC2 application port, no NAT/ALB/ACM/Verified Access." : (var.enable_verified_access ? "Phase 2: Verified Access enabled; create the application CNAME after endpoint creation." : "Phase 1: create ACM validation CNAME, wait for ISSUED, then set enable_verified_access=true.")
}
