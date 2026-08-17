variable "name_prefix" { type = string }
variable "log_group_name" { type = string }
variable "log_retention_days" { type = number }
variable "alb_arn_suffix" { type = string }
variable "target_group_arn_suffix" { type = string }
variable "alert_email" { type = string }
variable "denied_request_threshold" { type = number }
variable "alb_5xx_threshold" { type = number }
variable "target_5xx_threshold" { type = number }
variable "instance_id" {
  type    = string
  default = ""
}
variable "enable_ec2_alarm" {
  type    = bool
  default = true
}
variable "enable_alb_alarms" {
  type    = bool
  default = true
}
variable "enable_verified_access_monitoring" {
  type    = bool
  default = true
}
variable "tags" { type = map(string) }
