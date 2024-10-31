resource "aws_lambda_function" "sf_lambda" {
  function_name = "salesforce-ingest"

  s3_bucket = var.s3_bucket
  s3_key    = var.s3_lambda_path
  #   s3_object_version = data.aws_s3_object.sf-lambda.version_id
  # source_code_hash = data.archive_file.lambda_src.output_base64sha256
  source_code_hash = filebase64sha256(var.zip_output_key)


  role    = aws_iam_role.sf_ingest_lambda_role.arn
  runtime = "python3.8"
  handler = "index.lambda_handler"
  timeout = 100
  layers = [
    aws_lambda_layer_version.simple_salesforce.arn,
    aws_lambda_layer_version.awswrangler.arn,
    "arn:aws:lambda:${var.aws_region}:123456789012:layer:AWSLambdaPowertoolsPythonV2:21"
  ]
  depends_on = [
    aws_s3_object.lambda_src_file,
    aws_iam_role.sf_ingest_lambda_role,
    aws_lambda_layer_version.simple_salesforce,
    aws_lambda_layer_version.awswrangler
  ]
  environment {
    variables = {
      secret_name = var.secret_name,
      bucket      = var.s3_bucket,
      region_name = var.aws_region
    }
  }
}

# data "aws_s3_object" "sf-lambda" {
#     bucket = var.s3_bucket
#     key = var.s3_lambda_path
# }

# data "archive_file" "lambda_src" {
#   type        = "zip"
#   source_file = "./index.py"
#   output_path = "./salesforce-lambda.zip"
# }

resource "aws_s3_object" "lambda_src_file" {
  bucket = var.s3_bucket
  key    = "lambda-functions/salesforce-lambda.zip"
  source = var.zip_output_key
  etag   = filemd5(var.zip_output_key)
}
