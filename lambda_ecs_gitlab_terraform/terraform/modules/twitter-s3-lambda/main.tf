terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.48.0"
    }
  }
}

resource "aws_lambda_function" "twitter_s3_lambda" {
  s3_bucket        = var.aws_s3_bucket_name
  s3_key           = "lambda-functions/twitter_s3_lambda.zip"
  source_code_hash = "lambda-functions/twitter_s3_lambda.zip"
  function_name    = "${var.environment}-twitter-s3-lambda"
  role             = aws_iam_role.lambda_role.arn
  handler          = "main.twitter_s3_lambda"
  runtime          = "python3.8"
  timeout          = 600
  memory_size      = 1024
  layers           = [var.data_compute_layer_arn, aws_lambda_layer_version.requests_layer.arn]
  environment {
    variables = {
      AWS_UPLOAD_BUCKET = var.aws_s3_bucket_name
      TWITTER_SECRET    = var.twitter_secret_value
      TWITTER_FIELDS    = var.twitter_fields
    }
  }
  depends_on = [
    aws_iam_role.lambda_role
  ]
}

resource "aws_lambda_layer_version" "requests_layer" {
  s3_bucket           = var.aws_s3_bucket_name
  s3_key              = "lambda-layers/requests-layer/python.zip"
  source_code_hash    = "lambda-layers/requests-layer/python.zip"
  layer_name          = "requests-layer"
  description         = "Contains telethon"
  compatible_runtimes = ["python3.8"]
}

resource "aws_scheduler_schedule" "twitter_lambda_sfn_trigger" {
  name       = "${var.environment}-twitter-s3-lambda-sfn-trigger"
  group_name = "default"

  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression          = "cron(00 10 ? * * *)"
  schedule_expression_timezone = "America/Scoresbysund" # UTC-01:00

  target {
    arn      = aws_sfn_state_machine.twitter_lambda_sfn_state_machine.arn
    role_arn = aws_iam_role.scheduler_role.arn
  }
}

