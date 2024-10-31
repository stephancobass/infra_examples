provider "aws" {
  region = "ap-southeast-2"
  default_tags {
    tags = {
      Application = "EverCare"
    }
  }
}

terraform {
  required_version = "1.5.7"
  backend "s3" {
    bucket         = "evercare-iac-terraform-state"
    key            = "service/evercare-global" 
    region         = "ap-southeast-2"
    dynamodb_table = "evercare-iac-terraform-state-lock-dynamo"
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.47.0"
    }
  }
}