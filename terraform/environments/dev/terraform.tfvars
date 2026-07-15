project_name        = "azure-devsecops"
environment         = "dev"
location            = "Central India"
resource_group_name = "rg-azure-devsecops-dev"

vnet_address_space      = ["10.10.0.0/16"]
subnet_address_prefixes = ["10.10.1.0/24"]

acr_sku = "Basic"