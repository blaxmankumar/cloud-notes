output "vnet_name" {
  description = "Virtual Network name."
  value       = azurerm_virtual_network.this.name
}

output "vnet_id" {
  description = "Virtual Network ID."
  value       = azurerm_virtual_network.this.id
}

output "subnet_name" {
  description = "Subnet name."
  value       = azurerm_subnet.this.name
}

output "subnet_id" {
  description = "Subnet ID."
  value       = azurerm_subnet.this.id
}