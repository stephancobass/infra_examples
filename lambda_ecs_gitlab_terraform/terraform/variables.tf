#Environment variables
variable "environment" {
  type = string
}

variable "aws_region" {
  type = string
}

#GitLab
variable "gitlab_access_token" {
  type = string
}

# AWS variables
variable "aws_account_id" {
  type    = string
}

variable "aws_access_key" {
  type    = string
}

variable "aws_secret_key" {
  type    = string
}

#IAM resources and S3 bucket
variable "aws_iam_snowflake_si_policy" {
  type = string
}

variable "aws_iam_snowflake_si_role" {
  type = string
}

variable "aws_s3_bucket_name" {
  type = string
}

#Snowflake variables
variable "snowflake_account" {
  type = string
}

variable "snowflake_user" {
  type = string
}

variable "snowflake_password" {
  type = string
}

variable "snowflake_role" {
  type = string
}

variable "snowflake_region" {
  type = string
}

variable "snowflake_warehouse" {
  type = string
}

variable "snowflake_database" {
  type = string
}

variable "snowflake_storage_integration_name" {
  type = string
}

# Telegram variables
variable "default_telegram_timestamp_format" {
  type = string
}

variable "default_telegram_channels_list" {
  type = string
}

variable "telegram_secret_value" {
  type = string
}

# Twitter variables
variable "twitter_secret_value" { 
  type = string
}

variable "twitter_fields" {
    type = string
}