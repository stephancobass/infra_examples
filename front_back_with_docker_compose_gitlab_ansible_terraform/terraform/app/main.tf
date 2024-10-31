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
    key            = "service/app-app" 
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

data "terraform_remote_state" "app-vpc" {
  backend = "s3"
  config = {
    bucket         = "app-iac-terraform-state"
    key            = "service/app-vpc" 
    region         = "ap-southeast-2"
  }
  workspace = "${var.env_name}-vpc-${var.app_name}"
}

data "terraform_remote_state" "app-global" {
  backend = "s3"
  config = {
    bucket         = "app-iac-terraform-state"
    key            = "service/app-global" 
    region         = "ap-southeast-2"
  }
}

data "aws_availability_zones" "available" {}

locals {
  vpc_id                        = data.terraform_remote_state.app-vpc.outputs.app_vpc_id
  public_subnet_id              = data.terraform_remote_state.app-vpc.outputs.app_subnet_public
  key_pair_custom_name          = data.terraform_remote_state.app-global.outputs.key_pair_custom_name
  environment                   = "${var.env_name}-${var.app_name}"
  availability_zone             = data.aws_availability_zones.available.names[0]


  common_tags = {
    Name         = local.environment
  }
}
