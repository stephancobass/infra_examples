resource "aws_security_group" "ecs_lb" {
  name = "ecs-lb-${local.environment}"

  description = "Allow HTTP/HTTPs inbound traffic"
  vpc_id      = local.vpc_id


  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.common_tags
}

# Traffic to the ECS Cluster should only come from the load balancer.
resource "aws_security_group" "ecs_tasks" {
  name = "ecs-tasks-${local.environment}"

  description = "Allow inbound access from the ALB only"
  vpc_id      = local.vpc_id

  
  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.common_tags
}

resource "aws_security_group_rule" "frontend_ecs" {
  security_group_id = aws_security_group.ecs_tasks.id
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  source_security_group_id = aws_security_group.ecs_lb.id
  
}

resource "aws_security_group_rule" "api_ecs" {
  security_group_id = aws_security_group.ecs_tasks.id
  type              = "ingress"
  from_port         = 3001
  to_port           = 3001
  protocol          = "tcp"
  source_security_group_id = aws_security_group.ecs_lb.id
}

### Load balancer.
resource "aws_lb" "app" {
  name = "alb-${local.environment}"

  load_balancer_type = "application"

  subnets         = local.public_subnet_ids
  security_groups = [aws_security_group.ecs_lb.id]

  tags = local.common_tags
}

# Redirect all traffic from the load balancer to the target group.
resource "aws_alb_listener" "http" {
  load_balancer_arn = aws_lb.app.id
  port              = "80"
  protocol          = "HTTP"
  
  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}


resource "aws_alb_listener" "https" {
  load_balancer_arn = aws_lb.app.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = aws_acm_certificate_validation.cert.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend.arn
  }
}

resource "aws_lb_listener_rule" "api_routing" {
  listener_arn = aws_alb_listener.https.arn

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api.arn
  }

  condition {
    host_header {
      values = ["${var.env_name}" == "prod" ?  "api.${var.domain_name_zone}" : "api-${var.env_name}.${var.domain_name_zone}"]
    }
  }
}

resource "aws_lb_target_group" "frontend" {
  name        = "tg-${local.environment}-frontend"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = local.vpc_id
  target_type = "ip"

  health_check {
    interval            = 30
    path                = "/robots.txt"
    port                = 80
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    protocol            = "HTTP"
    matcher             = "200"
  }

}

resource "aws_lb_target_group" "api" {
  name        = "tg-${local.environment}-api"
  port        = 3001
  protocol    = "HTTP"
  vpc_id      = local.vpc_id
  target_type = "ip"

  health_check {
    interval            = 30
    path                = "/health"
    port                = 3001
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    protocol            = "HTTP"
    matcher             = "200"
  }

}
