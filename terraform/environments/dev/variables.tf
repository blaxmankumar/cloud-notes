variable "azure_subscription_id" {
  description = "Azure subscription ID."
  type        = string
}

variable "project_name" {
  description = "Project name."
  type        = string
}

variable "environment" {
  description = "Environment name."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "resource_group_name" {
  description = "Azure Resource Group name."
  type        = string
}

variable "vnet_address_space" {
  description = "Virtual Network address space."
  type        = list(string)
}

variable "subnet_address_prefixes" {
  description = "Subnet address prefixes."
  type        = list(string)
}

variable "acr_sku" {
  description = "Azure Container Registry SKU."
  type        = string
  default     = "Basic"
}