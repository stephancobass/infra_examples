output "aws_ecr_frontend_url" {
  value = aws_ecr_repository.frontend.repository_url
}

output "aws_ecr_backend_url" {
  value = aws_ecr_repository.backend.repository_url
}

output "aws_ecr_api_url" {
  value = aws_ecr_repository.api.repository_url
}

output "aws_ecr_worker_url" {
  value = aws_ecr_repository.worker.repository_url
}