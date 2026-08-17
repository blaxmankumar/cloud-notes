output "instance_id" { value = try(aws_verifiedaccess_instance.this[0].id, null) }
output "trust_provider_id" { value = try(aws_verifiedaccess_trust_provider.identity_center[0].id, null) }
output "group_id" { value = try(aws_verifiedaccess_group.this[0].verifiedaccess_group_id, null) }
output "endpoint_id" { value = try(aws_verifiedaccess_endpoint.this[0].id, null) }
output "endpoint_domain" { value = try(aws_verifiedaccess_endpoint.this[0].endpoint_domain, null) }
output "identity_center_instance_arns" { value = var.enabled ? tolist(data.aws_ssoadmin_instances.current[0].arns) : [] }
