terraform {
  required_providers {
    snowflake = {
      source  = "Snowflake-Labs/snowflake"
      version = "~> 0.54.0"
    }
  }
}

resource "snowflake_storage_integration" "aws_sf" {
  name    = var.snowflake_storage_integration_name
  comment = "A storage integration to AWS S3 for Snowflake House project."
  type    = "EXTERNAL_STAGE"
  enabled = true

  storage_allowed_locations = [ "s3://${var.aws_s3_bucket_name}/" ]
  storage_provider         = "S3"
  storage_aws_role_arn     = "arn:aws:iam::${var.aws_account_id}:role/${var.aws_iam_snowflake_si_role}"
}

resource "aws_iam_policy" "snowflake_si_policy" {
  name        = var.aws_iam_snowflake_si_policy
  description = "Policy to access s3 bucket from snowflake for Snowflake house project"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:DeleteObject",
          "s3:DeleteObjectVersion"
        ]
        Resource = [
          "arn:aws:s3:::${var.aws_s3_bucket_name}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ]
        Resource = "arn:aws:s3:::${var.aws_s3_bucket_name}"
      }
    ]
  })
}

resource "aws_iam_role" "snowflake_si_role" {
  name = var.aws_iam_snowflake_si_role

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          AWS = snowflake_storage_integration.aws_sf.storage_aws_iam_user_arn
        }
        Condition = {
          StringEquals = {
            "sts:ExternalId" = snowflake_storage_integration.aws_sf.storage_aws_external_id
          }
        }
      },
    ]
  })

  managed_policy_arns  = [ aws_iam_policy.snowflake_si_policy.arn ]
}
