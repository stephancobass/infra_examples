output "frontend_url" {
  value = aws_route53_record.frontend.name
}

output "api_url" {
  value = aws_route53_record.api.name
}

output "alb_url" {
  value = aws_lb.app.dns_name
}

output "redis_primary_endpoint" {
 value = aws_elasticache_replication_group.redis_replication_group.primary_endpoint_address
}

output "redis_reader_endpoint" {
 value = aws_elasticache_replication_group.redis_replication_group.reader_endpoint_address
}
