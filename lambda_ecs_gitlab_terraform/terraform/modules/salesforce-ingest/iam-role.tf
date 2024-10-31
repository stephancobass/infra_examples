resource "aws_iam_role" "sf_ingest_lambda_role" {
  name = "Salesforce-lambda"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : "sts:AssumeRole",
        "Principal" : {
          "Service" : "lambda.amazonaws.com"
        },
        "Effect" : "Allow",
        "Sid" : ""
      }
    ]
  })
}

resource "aws_iam_policy" "execution_role" {
  name        = "sf-ingest-execution-role"
  path        = "/"
  description = "Basic execution role"

  policy = jsonencode({
    "Statement" : [
      {
        "Action" : [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        "Effect" : "Allow",
        "Resource" : "arn:aws:logs:${var.aws_region}:*:*"
      },
      {
        "Action" : [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        "Effect" : "Allow",
        "Resource" : [
          "arn:aws:logs:${var.aws_region}:*:log-group:/aws/lambda/sf-ingest:*"
        ]
      },
      {
        "Action" : [
          "s3:PutObject",
          "s3:GetObject"
        ],
        "Effect" : "Allow",
        "Resource" : "arn:aws:s3:::${var.s3_bucket}/*"
      },
      {
        "Action" : "s3:ListBucket",
        "Effect" : "Allow",
        "Resource" : "arn:aws:s3:::${var.s3_bucket}"
      },
      {
        "Action" : [
          "secretsmanager:DescribeSecret",
          "secretsmanager:GetSecretValue"
        ],
        "Effect" : "Allow",
        "Resource" : "arn:aws:secretsmanager:${var.aws_region}:*:secret:dev/salesforce-api-access-sMzLCU"
      }
    ],
    "Version" : "2012-10-17"
  })

}

resource "aws_iam_role_policy_attachment" "execution_role_attachment" {
  role       = aws_iam_role.sf_ingest_lambda_role.name
  policy_arn = aws_iam_policy.execution_role.arn

}

resource "aws_iam_role" "sf_ingest_stepfunction_role" {
  name = "Salesforce-sfn"
  assume_role_policy = jsonencode({
    "Statement" : [
      {
        "Sid" : "",
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "states.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      }
    ],
    "Version" : "2012-10-17"
  })
}

resource "aws_iam_policy" "step_function" {
  name        = "sf-ingest-stepfunction-role"
  path        = "/"
  description = "Stepfunction execution"
  policy = jsonencode({
    "Statement" : [

      {
        "Effect" : "Allow",
        "Action" : [
          "sns:Publish"
        ],
        "Resource" : [
          "arn:aws:sns:${var.aws_region}:*:*"
        ]
      },

      {
        "Effect" : "Allow",
        "Action" : [
          "states:StartExecution"
        ],
        "Resource" : [
          "arn:aws:states:${var.s3_bucket}:*:stateMachine:Salesforce"
        ]
      },
      {
        "Action" : [
          "s3:GetObject"
        ],
        "Effect" : "Allow",
        "Resource" : "arn:aws:s3:::${var.s3_bucket}/*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "lambda:InvokeFunction"
        ],
        "Resource" : [
          "${aws_lambda_function.sf_lambda.arn}",
          "${aws_lambda_function.sf_lambda.arn}:*"
        ]
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "logs:CreateLogDelivery",
          "logs:GetLogDelivery",
          "logs:UpdateLogDelivery",
          "logs:DeleteLogDelivery",
          "logs:ListLogDeliveries",
          "logs:PutLogEvents",
          "logs:PutResourcePolicy",
          "logs:DescribeResourcePolicies",
          "logs:DescribeLogGroups"
        ],
        "Resource" : "*"
      }
    ],
    "Version" : "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "step_function_attachment" {
  role       = aws_iam_role.sf_ingest_stepfunction_role.name
  policy_arn = aws_iam_policy.step_function.arn
}
