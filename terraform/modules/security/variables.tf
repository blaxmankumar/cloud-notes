variable "name_prefix" { type = string }
variable "vpc_id" { type = string }
variable "vpc_cidr" { type = string }
variable "application_port" { type = number }
variable "free_tier_mode" {
  type    = bool
  default = false
}
variable "tags" { type = map(string) }
