resource "random_string" "acr_suffix" {
  length  = 6
  upper   = false
  special = false
}

locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }

  vnet_name   = "vnet-${var.project_name}-${var.environment}"
  subnet_name = "snet-app-${var.environment}"

  acr_name = lower(
    replace(
      "${var.project_name}${var.environment}${random_string.acr_suffix.result}",
      "-",
      ""
    )
  )
}

module "resource_group" {
  source = "../../modules/resource-group"

  name     = var.resource_group_name
  location = var.location
  tags     = local.common_tags
}

module "networking" {
  source = "../../modules/networking"

  resource_group_name = module.resource_group.name
  location            = module.resource_group.location

  vnet_name          = local.vnet_name
  vnet_address_space = var.vnet_address_space

  subnet_name             = local.subnet_name
  subnet_address_prefixes = var.subnet_address_prefixes

  tags = local.common_tags
}

module "acr" {
  source = "../../modules/acr"

  resource_group_name = module.resource_group.name
  location            = module.resource_group.location

  name          = local.acr_name
  sku           = var.acr_sku
  admin_enabled = false

  tags = local.common_tags
}