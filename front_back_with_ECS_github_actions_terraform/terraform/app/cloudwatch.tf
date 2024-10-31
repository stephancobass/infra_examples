# Creating log groups
resource "aws_cloudwatch_log_group" "logs_frontend" {
  name              = "/ecs/${replace(var.env_name, "-", "/")}/${var.app_name}/frontend"
  retention_in_days = var.logs_retention_in_days
  skip_destroy      = true
  tags              = local.common_tags
}

resource "aws_cloudwatch_log_group" "logs_api" {
  name              = "/ecs/${replace(var.env_name, "-", "/")}/${var.app_name}/api"
  retention_in_days = var.logs_retention_in_days
  skip_destroy      = true
  tags              = local.common_tags
}

resource "aws_cloudwatch_log_group" "logs_worker" {
  name              = "/ecs/${replace(var.env_name, "-", "/")}/${var.app_name}/worker"
  retention_in_days = var.logs_retention_in_days
  skip_destroy      = true
  tags              = local.common_tags
}

resource "aws_cloudwatch_log_group" "logs_redis" {
  name              = "/redis-replication-group/${replace(var.env_name, "-", "/")}/${var.app_name}/redis"
  retention_in_days = var.logs_retention_in_days
  skip_destroy      = true
  tags              = local.common_tags
}

# Creating alarms
resource "aws_cloudwatch_metric_alarm" "target_healthy_count_frontend" {
  alarm_name          = "tg-${local.environment}-frontend-healthy-count"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "HealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = "60"
  statistic           = "Average"
  threshold           = "0"

  dimensions = {
    LoadBalancer = aws_lb.app.arn_suffix
    TargetGroup  = aws_lb_target_group.frontend.arn_suffix
  }

  alarm_description  = "Trigger an alert when the target group - ${aws_lb_target_group.frontend.name} has 1 or more unhealthy hosts"
  alarm_actions      = [aws_sns_topic.cloudwatch_alarms_frontend.arn]
  ok_actions         = [aws_sns_topic.cloudwatch_alarms_frontend.arn]
  treat_missing_data = "breaching"
}

resource "aws_cloudwatch_metric_alarm" "target_healthy_count_api" {
  alarm_name          = "tg-${local.environment}-api-healthy-count"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "HealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = "60"
  statistic           = "Average"
  threshold           = "0"

  dimensions = {
    LoadBalancer = aws_lb.app.arn_suffix
    TargetGroup  = aws_lb_target_group.api.arn_suffix
  }

  alarm_description  = "Trigger an alert when the target group - ${aws_lb_target_group.api.name} has 1 or more unhealthy hosts"
  alarm_actions      = [aws_sns_topic.cloudwatch_alarms_api.arn]
  ok_actions         = [aws_sns_topic.cloudwatch_alarms_api.arn]
  treat_missing_data = "breaching"
}

# resource "aws_cloudwatch_metric_alarm" "target_healthy_count_worker" {
#   alarm_name          = "${local.environment}-worker-healthy-count"
#   comparison_operator = "LessThanOrEqualToThreshold"
#   evaluation_periods  = "1"
#   metric_name         = "HealthyHostCount"
#   namespace           = "AWS/ApplicationELB"
#   period              = "60"
#   statistic           = "Average"
#   threshold           = "0"

#   #dimensions = {
#   #  LoadBalancer = aws_lb.app.arn_suffix
#   #  TargetGroup  = aws_lb_target_group.api.arn_suffix
#   #}

#   alarm_description  = "Trigger an alert when the target group - ${aws_lb_target_group.api.name} has 1 or more unhealthy hosts"
#   alarm_actions      = [aws_sns_topic.cloudwatch_alarms_api.arn]
#   ok_actions         = [aws_sns_topic.cloudwatch_alarms_api.arn]
#   treat_missing_data = "breaching"
# }