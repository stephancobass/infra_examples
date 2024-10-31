provider "aws" {
  region = "us-east-2"
  default_tags {
    tags = {
      Application = "app"
    }
  }
}

terraform {
  required_version = ">= 1.7.0"
  backend "s3" {
    bucket         = "app-iac-terraform-state"
    key            = "service/app-ecr" 
    region         = "us-east-2"
    dynamodb_table = "app-terraform-state-lock-dynamo"
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.34.0"
    }
  }
}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

locals {
  environment = "${var.env_name}-${var.app_name}"

  common_tags = {
    Name         = local.environment
  }
}
