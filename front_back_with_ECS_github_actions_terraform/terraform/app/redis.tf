
resource "aws_security_group" "redis_sg" {
  name = "redis_sg-${local.environment}"

  description = "Allow inbound access from ECS tasks to Redis cluster"
  vpc_id      = local.vpc_id

  
  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.common_tags
}

resource "aws_security_group_rule" "redis_ingress" {
  security_group_id = aws_security_group.redis_sg.id
  type              = "ingress"
  from_port         = 6379
  to_port           = 6379
  protocol          = "tcp"
  source_security_group_id = aws_security_group.ecs_tasks.id
  
}

resource "aws_elasticache_subnet_group" "redis_subnet_group" {
  name       = "redis-subnet-group-${local.environment}"
  subnet_ids = local.private_subnet_ids
}

resource "aws_elasticache_replication_group" "redis_replication_group" {
  replication_group_id          = "redis-replication-group-${local.environment}"
  description                   = "Redis replication group for ${local.environment} environment"
  
  engine                        = "redis"
  engine_version                = "7.1"
  node_type                     = "cache.t3.micro"
  parameter_group_name          = "default.redis7"
  num_cache_clusters            = 2
  
  apply_immediately             = true
  automatic_failover_enabled    = true

  at_rest_encryption_enabled    = true
  transit_encryption_enabled    = true
  
  log_delivery_configuration {
    destination      = aws_cloudwatch_log_group.logs_redis.name
    destination_type = "cloudwatch-logs"
    log_format       = "text"
    log_type         = "engine-log"
  }
  

  subnet_group_name             = aws_elasticache_subnet_group.redis_subnet_group.name
  security_group_ids            = [aws_security_group.redis_sg.id]
  port                          = 6379
}