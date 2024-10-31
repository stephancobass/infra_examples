terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.2.0"
    }
  }
  required_version = ">= 1.2.0"
}

provider "aws" {
  region     = var.aws_region
  access_key = var.access_key
  secret_key = var.secret_key
}

resource "aws_secretsmanager_secret" "salesforce" {
  name = "dev/salesforce-api-access"

  lifecycle {
    prevent_destroy = true
  }
}

# resource "null_resource" "archiver" {
#   provisioner "local-exec" {
#     command = "/bin/bash build_lambda.sh"
#   }
#   triggers = {
#     source_file = filebase64sha256(var.zip_output_key)
#   }
# }
