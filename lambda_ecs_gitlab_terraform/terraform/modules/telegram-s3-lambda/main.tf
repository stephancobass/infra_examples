terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.48.0"
    }
  }
}

resource "aws_lambda_function" "telegram_s3_lambda" {
  s3_bucket        = var.aws_s3_bucket_name
  s3_key           = "lambda-functions/telegram_s3_lambda.zip"
  source_code_hash = "lambda-functions/telegram_s3_lambda.zip"
  function_name    = "${var.environment}-telegram-s3-lambda"
  role             = aws_iam_role.lambda_role.arn
  handler          = "main.telegram_s3_lambda"
  runtime          = "python3.8"
  timeout          = 600
  memory_size      = 1024
  layers           = [aws_lambda_layer_version.telegram_layer.arn, aws_lambda_layer_version.data_compute_layer.arn]

  environment {
    variables = {
      AWS_UPLOAD_BUCKET        = var.aws_s3_bucket_name
      TELEGRAM_SECRET          = var.telegram_secret_value
      DEFAULT_TIMESTAMP_FORMAT = var.default_telegram_timestamp_format
      DEFAULT_CHANNELS_LIST    = var.default_telegram_channels_list
    }
  }
  depends_on = [
    aws_iam_role.lambda_role,
    aws_lambda_layer_version.telegram_layer,
    aws_lambda_layer_version.data_compute_layer
  ]
}

resource "aws_lambda_layer_version" "data_compute_layer" {
  s3_bucket           = var.aws_s3_bucket_name
  s3_key              = "lambda-layers/data-compute-layer/python.zip"
  source_code_hash    = "lambda-layers/data-compute-layer/python.zip"
  layer_name          = "data-compute-layer"
  description         = "Contains pandas, numpy, fastparquet and pyarrow"
  compatible_runtimes = ["python3.8"]
}

resource "aws_lambda_layer_version" "telegram_layer" {
  s3_bucket           = var.aws_s3_bucket_name
  s3_key              = "lambda-layers/telegram-layer/python.zip"
  source_code_hash    = "lambda-layers/telegram-layer/python.zip"
  layer_name          = "telegram-layer"
  description         = "Contains telethon"
  compatible_runtimes = ["python3.8"]
}

resource "aws_scheduler_schedule" "telegram_lambda_sfn_trigger" {
  name       = "${var.environment}-telegram-s3-lambda-sfn-trigger"
  group_name = "default"

  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression          = "cron(00 10 ? * * *)"
  schedule_expression_timezone = "America/Scoresbysund" # UTC-01:00

  target {
    arn      = aws_sfn_state_machine.telegram_lambda_sfn_state_machine.arn
    role_arn = aws_iam_role.scheduler_role.arn
  }
}

