# S3 bucket for backups
resource "aws_s3_bucket" "app_backups" {
    
    bucket = var.s3_backups

    lifecycle {
      prevent_destroy = true
    }
}

resource "aws_s3_bucket" "app_data" {
    
    bucket = var.s3_data

    lifecycle {
      prevent_destroy = true
    }
}