resource "aws_ecr_repository" "frontend" {
  name = "${local.environment}-frontend"
  force_delete = false
  image_scanning_configuration {
    scan_on_push = true
  }

  tags = local.common_tags
}

resource "aws_ecr_lifecycle_policy" "frontend" {
  repository = aws_ecr_repository.frontend.name

  policy = <<EOF
{
    "rules": [
        {
            "rulePriority": 1,
            "description": "Keep last ${var.ecr_image_count} images",
            "selection": {
              "countType": "imageCountMoreThan",
              "countNumber": ${var.ecr_image_count},
              "tagStatus": "any"
            },
            "action": {
                "type": "expire"
            }
        }
    ]
}
EOF
}

resource "aws_ecr_repository" "backend" {
  name = "${local.environment}-backend"
  force_delete = false
  image_scanning_configuration {
    scan_on_push = true
  }

  tags = local.common_tags
}

resource "aws_ecr_lifecycle_policy" "backend" {
  repository = aws_ecr_repository.backend.name

  policy = <<EOF
{
    "rules": [
        {
            "rulePriority": 1,
            "description": "Keep last ${var.ecr_image_count} images",
            "selection": {
              "countType": "imageCountMoreThan",
              "countNumber": ${var.ecr_image_count},
              "tagStatus": "any"
            },
            "action": {
                "type": "expire"
            }
        }
    ]
}
EOF
}

resource "aws_ecr_repository" "api" {
  name = "${local.environment}-api"
  force_delete = false
  image_scanning_configuration {
    scan_on_push = true
  }

  tags = local.common_tags
}

resource "aws_ecr_lifecycle_policy" "api" {
  repository = aws_ecr_repository.api.name

  policy = <<EOF
{
    "rules": [
        {
            "rulePriority": 1,
            "description": "Keep last ${var.ecr_image_count} images",
            "selection": {
              "countType": "imageCountMoreThan",
              "countNumber": ${var.ecr_image_count},
              "tagStatus": "any"
            },
            "action": {
                "type": "expire"
            }
        }
    ]
}
EOF
}

resource "aws_ecr_repository" "worker" {
  name = "${local.environment}-worker"
  force_delete = false
  image_scanning_configuration {
    scan_on_push = true
  }

  tags = local.common_tags
}

resource "aws_ecr_lifecycle_policy" "worker" {
  repository = aws_ecr_repository.worker.name

  policy = <<EOF
{
    "rules": [
        {
            "rulePriority": 1,
            "description": "Keep last ${var.ecr_image_count} images",
            "selection": {
              "countType": "imageCountMoreThan",
              "countNumber": ${var.ecr_image_count},
              "tagStatus": "any"
            },
            "action": {
                "type": "expire"
            }
        }
    ]
}
EOF
}