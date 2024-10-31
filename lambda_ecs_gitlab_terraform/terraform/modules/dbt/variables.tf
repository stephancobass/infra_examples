
# AWS variables
variable "environment" {
  type    = string
}

variable "aws_account_id" {
  type    = string
}

variable "aws_region" {
  type    = string
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