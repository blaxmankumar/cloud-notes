output "resource_group_name" {
  description = "Created Azure Resource Group name."
  value       = module.resource_group.name
}

output "resource_group_id" {
  description = "Created Azure Resource Group ID."
  value       = module.resource_group.id
}

output "vnet_name" {
  description = "Created Virtual Network name."
  value       = module.networking.vnet_name
}

output "vnet_id" {
  description = "Created Virtual Network ID."
  value       = module.networking.vnet_id
}

output "subnet_name" {
  description = "Created subnet name."
  value       = module.networking.subnet_name
}

output "subnet_id" {
  description = "Created subnet ID."
  value       = module.networking.subnet_id
}

output "acr_name" {
  description = "Created Azure Container Registry name."
  value       = module.acr.name
}

output "acr_id" {
  description = "Created Azure Container Registry ID."
  value       = module.acr.id
}

output "acr_login_server" {
  description = "Azure Container Registry login server."
  value       = module.acr.login_server
}