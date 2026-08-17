variable "name_prefix" { type = string }
variable "vpc_id" { type = string }
variable "subnet_ids" { type = list(string) }
variable "security_group_id" { type = string }
variable "instance_id" { type = string }
variable "application_port" { type = number }
variable "tags" { type = map(string) }
