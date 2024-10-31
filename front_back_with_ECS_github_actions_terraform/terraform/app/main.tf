provider "aws" {
  region = "us-east-2"
  default_tags {
    tags = {
      Application = "Command Center"
    }
  }
}

terraform {
  required_version = ">= 1.7.0"
  backend "s3" {
    bucket         = "app-iac-terraform-state"
    key            = "service/app-app" 
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

data "terraform_remote_state" "app-vpc" {
  backend = "s3"
  config = {
    bucket         = "app-iac-terraform-state"
    key            = "service/app-vpc" 
    region         = "us-east-2"
  }
  workspace = "${var.env_name}-${var.app_name}-vpc"
}

data "terraform_remote_state" "app-ecr" {
  backend = "s3"
  config = {
    bucket         = "app-iac-terraform-state"
    key            = "service/app-ecr" 
    region         = "us-east-2"
  }
  workspace = "${var.env_name}-${var.app_name}-ecr"
}


data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

locals {
  vpc_id                        = data.terraform_remote_state.app-vpc.outputs.app_vpc_id
  public_subnet_ids             = data.terraform_remote_state.app-vpc.outputs.app_subnets_public
  private_subnet_ids            = data.terraform_remote_state.app-vpc.outputs.app_subnets_private
  ecr_frontend_repository_url   = data.terraform_remote_state.app-ecr.outputs.aws_ecr_frontend_url
  ecr_api_repository_url        = data.terraform_remote_state.app-ecr.outputs.aws_ecr_api_url
  ecr_worker_repository_url     = data.terraform_remote_state.app-ecr.outputs.aws_ecr_worker_url
  environment                   = "${var.env_name}-${var.app_name}"
  region                        = data.aws_region.current.name
  account                       = data.aws_caller_identity.current.account_id

  common_tags = {
    Name         = local.environment
  }
}
