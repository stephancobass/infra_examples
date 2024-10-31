variable "aws_region" {
  type    = string
  default = "us-west-2"
}

variable "secret_name" {
  type    = string
  default = "dev/salesforce-api-access"
}

variable "aws_s3_bucket_name" {
  type    = string
  default = "snowflake-house"
}

variable "s3_lambda_path" {
  type    = string
  default = "lambda-functions/salesforce-lambda.zip"
}

variable "entity_key" {
  type    = string
  default = "Salesforce/entity_list.json"
}

variable "zip_output_key" {
  type    = string
  default = "./salesforce-lambda.zip"
}
