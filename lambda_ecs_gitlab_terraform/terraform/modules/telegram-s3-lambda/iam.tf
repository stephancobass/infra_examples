# IAM resources for lambda
resource "aws_iam_role" "lambda_role" {
  name               = "${var.environment}-telegram-s3-lambda"
  assume_role_policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": "sts:AssumeRole",
     "Principal": {
       "Service": "lambda.amazonaws.com"
     },
     "Effect": "Allow",
     "Sid": ""
   }
 ]
}
EOF
}

resource "aws_iam_policy" "lambda_iam_policy" {

  name        = "${var.environment}-telegram-s3-lambda"
  path        = "/"
  description = "AWS IAM Policy for managing a dedicated Lambda role"
  policy      = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": [
       "logs:CreateLogGroup",
       "logs:CreateLogStream",
       "logs:PutLogEvents"
     ],
     "Resource": "arn:aws:logs:*:*:*",
     "Effect": "Allow"
   },
   {
      "Action": [
        "s3:PutObject",
        "s3:GetObject"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:s3:::${var.aws_s3_bucket_name}/*"
    },
    {
      "Action": [
        "secretsmanager:DescribeSecret",
        "secretsmanager:GetSecretValue"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:secretsmanager:${var.aws_region}:123456789012:secret:*"
    }
 ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lambda_iam_policy_attachment" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_iam_policy.arn
}

# IAM resources for StepFunction
resource "aws_iam_role" "step_function_role" {
  name               = "${var.environment}-telegram-s3-lambda-sfn"
  assume_role_policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": "sts:AssumeRole",
     "Principal": {
       "Service": "states.${var.aws_region}.amazonaws.com"
     },
     "Effect": "Allow",
     "Sid": ""
   }
 ]
}
EOF
}

resource "aws_iam_policy" "step_function_policy" {

  name        = "${var.environment}-telegram-s3-lambda-sfn"
  path        = "/"
  description = "AWS IAM Policy for managing StepFunctions StateMachine interaction with Lambda function"
  policy      = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "lambda:InvokeFunction"
            ],
            "Resource": [
                "${aws_lambda_function.telegram_s3_lambda.arn}"
            ]
        },
        {
          "Action": [
            "s3:PutObject",
            "s3:GetObject"
          ],
          "Effect": "Allow",
          "Resource": "arn:aws:s3:::${var.aws_s3_bucket_name}/*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "xray:PutTraceSegments",
                "xray:PutTelemetryRecords",
                "xray:GetSamplingRules",
                "xray:GetSamplingTargets"
            ],
            "Resource": [
                "*"
            ]
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "step_function_iam_policy_attachment" {
  role       = aws_iam_role.step_function_role.name
  policy_arn = aws_iam_policy.step_function_policy.arn
}

# IAM resources and StepFunction Scheduler
resource "aws_iam_role" "scheduler_role" {
  name               = "${var.environment}-telegram-s3-lambda-sfn-scheduler"
  assume_role_policy = <<EOF
    {
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
                "Service": "scheduler.amazonaws.com"
                },
            "Effect": "Allow",
            "Sid": ""
            }
        ]
    }
    EOF
}

resource "aws_iam_policy" "scheduler_policy" {

  name        = "${var.environment}-telegram-s3-lambda-sfn-scheduler"
  path        = "/"
  description = "AWS IAM Policy for managing StepFunctions StateMachine trigger"
  policy      = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "states:StartExecution"
            ],
            "Resource": [
                "${aws_sfn_state_machine.telegram_lambda_sfn_state_machine.arn}"
            ]
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "scheduler_iam_policy_attachment" {
  role       = aws_iam_role.scheduler_role.name
  policy_arn = aws_iam_policy.scheduler_policy.arn
}