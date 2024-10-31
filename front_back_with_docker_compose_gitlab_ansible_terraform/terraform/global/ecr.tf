resource "aws_ecr_repository" "gitlab-ci" {
  name = "${var.app_name}-gitlab-ci"
  force_delete = false
  image_scanning_configuration {
    scan_on_push = true
  }

}

resource "aws_ecr_lifecycle_policy" "gitlab-ci" {
  repository = aws_ecr_repository.gitlab-ci.name

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