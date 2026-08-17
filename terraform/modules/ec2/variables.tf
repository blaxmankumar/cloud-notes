variable "name_prefix" { type = string }
variable "subnet_id" { type = string }
variable "security_group_id" { type = string }
variable "instance_type" { type = string }
variable "artifact_bucket_name" { type = string }
variable "root_volume_size" { type = number }
variable "tags" { type = map(string) }
