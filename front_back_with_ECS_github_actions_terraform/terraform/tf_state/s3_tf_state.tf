# Terraform state file setup
# Create an S3 bucket to store the terraform state files
resource "aws_s3_bucket" "terraform_state" {
    
    bucket = var.s3_tf_state_name

    lifecycle {
      prevent_destroy = true
    }
}

resource "aws_s3_bucket_versioning" "terraform_state_versioning" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}