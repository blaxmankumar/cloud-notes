variable "resource_group_name" {
  description = "Resource Group name."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "name" {
  description = "Azure Container Registry name."
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9]{5,50}$", var.name))
    error_message = "ACR name must contain only letters and numbers and must be 5 to 50 characters long."
  }
}

variable "sku" {
  description = "Azure Container Registry SKU."
  type        = string
  default     = "Basic"

  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.sku)
    error_message = "ACR SKU must be Basic, Standard, or Premium."
  }
}

variable "admin_enabled" {
  description = "Enable or disable ACR admin user."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags applied to ACR."
  type        = map(string)
  default     = {}
}