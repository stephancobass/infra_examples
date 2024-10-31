provider "aws" {
  region = "us-east-2"
  default_tags {
    tags = {
      Aplication = "Command Center"
    }
  }
}

terraform {
  required_version = ">= 1.7.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.34.0"
    }
  }
}
