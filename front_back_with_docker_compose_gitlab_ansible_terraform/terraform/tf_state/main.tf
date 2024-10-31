provider "aws" {
  region = "ap-southeast-2"
  default_tags {
    tags = {
      Aplication = "app"
    }
  }
}

terraform {
  required_version = "1.5.7"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.47.0"
    }
  }
}