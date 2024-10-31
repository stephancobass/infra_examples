output "app_vpc_id" {
  value = aws_vpc.app.id
}

output "app_subnet_public" {
  value = aws_subnet.public.id
}