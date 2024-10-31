# Frontend target group health status
resource "aws_sns_topic" "cloudwatch_alarms_frontend" {
  name = "${var.env_name}_cloudwatch_alarms_frontend"
}

resource "aws_sns_topic_subscription" "cloudwatch_alarms_email_frontend" {
  topic_arn = aws_sns_topic.cloudwatch_alarms_frontend.arn
  protocol  = "email"
  endpoint  = var.cloudwatch_alarm_email
}

# Backend target group health status
resource "aws_sns_topic" "cloudwatch_alarms_api" {
  name = "${var.env_name}_cloudwatch_alarms_api"
}

resource "aws_sns_topic_subscription" "cloudwatch_alarms_email_api" {
  topic_arn = aws_sns_topic.cloudwatch_alarms_api.arn
  protocol  = "email"
  endpoint  = var.cloudwatch_alarm_email
}