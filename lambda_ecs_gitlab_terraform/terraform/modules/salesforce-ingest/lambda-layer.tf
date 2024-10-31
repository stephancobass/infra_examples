resource "aws_lambda_layer_version" "simple_salesforce" {
  s3_bucket = var.s3_bucket
  s3_key    = "lambda-layers/simple-salesforce/python.zip"

  layer_name  = "simple-salesforce"
  description = "Python Simple salesforce 1.1.12 library"

  compatible_runtimes = ["python3.8"]
}

resource "aws_lambda_layer_version" "pandas" {
  s3_bucket = var.s3_bucket
  s3_key    = "lambda-layers/pandas/python.zip"

  layer_name  = "pandas"
  description = "Python Pandas 1.5.2 library"

  compatible_runtimes = ["python3.8", "python3.9", ]
}

resource "aws_lambda_layer_version" "awswrangler" {
  s3_bucket = var.s3_bucket
  s3_key    = "lambda-layers/awswrangler/awswrangler-layer-2.19.0-py3.8.zip"

  layer_name  = "awswrangler"
  description = "Python AWSwrangler 2.19.0 library"

  compatible_runtimes = ["python3.8"]
}
