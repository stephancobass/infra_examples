output "aws_ecr_backend_url" {
  value = aws_ecr_repository.backend.repository_url
}

output "aws_ecr_frontend_url" {
  value = aws_ecr_repository.frontend.repository_url
}