resource "aws_cloudwatch_log_group" "verified_access" {
  name              = var.log_group_name
  retention_in_days = var.log_retention_days
  tags              = var.tags
}

resource "aws_sns_topic" "alerts" {
  name = "verified-access-security-alerts"
  tags = var.tags
}

resource "aws_sns_topic_subscription" "email" {
  count     = trimspace(var.alert_email) == "" ? 0 : 1
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

resource "aws_cloudwatch_log_metric_filter" "verified_access_denied" {
  name           = "VerifiedAccessDeniedRequests"
  log_group_name = aws_cloudwatch_log_group.verified_access.name
  pattern        = "{ $.activity_id = \"2\" }"

  metric_transformation {
    name          = "VerifiedAccessDeniedRequests"
    namespace     = "Security/VerifiedAccess"
    value         = "1"
    default_value = "0"
    unit          = "Count"
  }
}

locals {
  alarms = {
    unhealthy_targets = {
      metric_name = "UnHealthyHostCount", namespace = "AWS/ApplicationELB", statistic = "Maximum", threshold = 1
      dimensions  = { LoadBalancer = var.alb_arn_suffix, TargetGroup = var.target_group_arn_suffix }
    }
    alb_5xx = {
      metric_name = "HTTPCode_ELB_5XX_Count", namespace = "AWS/ApplicationELB", statistic = "Sum", threshold = var.alb_5xx_threshold
      dimensions  = { LoadBalancer = var.alb_arn_suffix }
    }
    target_5xx = {
      metric_name = "HTTPCode_Target_5XX_Count", namespace = "AWS/ApplicationELB", statistic = "Sum", threshold = var.target_5xx_threshold
      dimensions  = { LoadBalancer = var.alb_arn_suffix, TargetGroup = var.target_group_arn_suffix }
    }
  }
}

resource "aws_cloudwatch_metric_alarm" "alb" {
  for_each            = local.alarms
  alarm_name          = "${var.name_prefix}-${each.key}"
  alarm_description   = "Operational alarm for ${each.key}"
  namespace           = each.value.namespace
  metric_name         = each.value.metric_name
  dimensions          = each.value.dimensions
  statistic           = each.value.statistic
  period              = 60
  evaluation_periods  = 2
  datapoints_to_alarm = 2
  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = each.value.threshold
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]
  tags                = var.tags
}

resource "aws_cloudwatch_metric_alarm" "verified_access_denied" {
  alarm_name          = "${var.name_prefix}-verified-access-denied"
  alarm_description   = "Verified Access denied requests exceeded the configured threshold"
  namespace           = "Security/VerifiedAccess"
  metric_name         = "VerifiedAccessDeniedRequests"
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = var.denied_request_threshold
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]
  tags                = var.tags

  depends_on = [aws_cloudwatch_log_metric_filter.verified_access_denied]
}
