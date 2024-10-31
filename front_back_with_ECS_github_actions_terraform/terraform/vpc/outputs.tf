output "app_vpc_id" {
  value = length(aws_vpc.app.0.id) > 0 ? aws_vpc.app.0.id : null
}

output "app_subnets_public" {
  value = aws_subnet.public[*].id
}

output "app_subnets_private" {
  value = aws_subnet.private[*].id
}