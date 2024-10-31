provider "aws" {
  region = "ap-southeast-2"
  default_tags {
    tags = {
      Application = "app"
    }
  }
}

terraform {
  required_version = "1.5.7"
  backend "s3" {
    bucket         = "app-iac-terraform-state"
    key            = "service/app-vpc" 
    region         = "ap-southeast-2"
    dynamodb_table = "app-iac-terraform-state-lock-dynamo"
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.47.0"
    }
  }
}

data "aws_region" "current" {}

locals {
  environment = "${var.env_name}-${var.app_name}"
  region = data.aws_region.current.name

  common_tags = {
    Name         = local.environment
  }
}
  