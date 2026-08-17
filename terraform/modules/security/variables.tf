variable "name_prefix" { type = string }
variable "vpc_id" { type = string }
variable "vpc_cidr" { type = string }
variable "application_port" { type = number }
variable "tags" { type = map(string) }
