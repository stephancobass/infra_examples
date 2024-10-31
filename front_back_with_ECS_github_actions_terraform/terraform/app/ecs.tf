# Defining "task definitions"
resource "aws_ecs_task_definition" "task_frontend" {
  family = "${local.environment}-frontend"
  container_definitions = jsonencode([
    {
      "essential": true,
      "image": "${local.ecr_frontend_repository_url}:${var.aws_ecr_image_tag}",
      "name": "${local.environment}-frontend",
      "memoryReservation": var.ecs_task_memory_frontend,
      "portMappings": [
        {
          "containerPort": 80, 
          "hostPort": 80 
        }
      ],
      "logConfiguration": {
          "logDriver": "awslogs",
          "options": {
              "awslogs-group": "/ecs/${var.env_name}/${var.app_name}/frontend",
              "awslogs-region": "${local.region}",
              "awslogs-stream-prefix": "ecs"
          }
      }
    }
  ])

  cpu          = var.ecs_task_cpu_frontend
  memory       = var.ecs_task_memory_hard_limit_frontend
  network_mode = "awsvpc"

  execution_role_arn       = aws_iam_role.ecsTaskExecutionRole.arn
  task_role_arn            = aws_iam_role.ecsTaskExecutionRole.arn

  requires_compatibilities = ["FARGATE"]

  lifecycle {
    ignore_changes = [container_definitions]
  }
}

resource "aws_ecs_task_definition" "task_api" {
  family = "${local.environment}-api"
  container_definitions = jsonencode([
    {
      "essential": true,
      "image": "${local.ecr_api_repository_url}:${var.aws_ecr_image_tag}",
      "name": "${local.environment}-api",
      "memoryReservation": var.ecs_task_memory_api,
      "portMappings": [
        {
          "containerPort": 3001, 
          "hostPort": 3001 
        }
      ],
      "logConfiguration": {
          "logDriver": "awslogs",
          "options": {
              "awslogs-group": "/ecs/${var.env_name}/${var.app_name}/api",
              "awslogs-region": "${local.region}",
              "awslogs-stream-prefix": "ecs"
          }
      },
      "environment": [
                {
                    "name": "NODE_ENV",
                    "value": "production"
                },
                {
                    "name": "LISTEN_PORT",
                    "value": "3001"
                },
                {
                    "name": "LISTEN_ADDRESS",
                    "value": "0.0.0.0"
                }
            ],
      "secrets": [
        {
        "name": "FE_APP_URL",
        "valueFrom": "arn:aws:ssm:${local.region}:${local.account}:parameter/${var.env_name}/${var.app_name}/FE_APP_URL"
          },
        {
        "name": "FE_APP_API_KEY",
        "valueFrom": "arn:aws:ssm:${local.region}:${local.account}:parameter/${var.env_name}/${var.app_name}/FE_APP_API_KEY"
          },
        {
        "name": "BULL_UI_BASIC_AUTH_USERNAME",
        "valueFrom": "arn:aws:ssm:${local.region}:${local.account}:parameter/${var.env_name}/${var.app_name}/BULL_UI_BASIC_AUTH_USERNAME"
          },
        {
        "name": "BULL_UI_BASIC_AUTH_PASSWORD",
        "valueFrom": "arn:aws:ssm:${local.region}:${local.account}:parameter/${var.env_name}/${var.app_name}/BULL_UI_BASIC_AUTH_PASSWORD"
          },
        {
        "name": "REDIS_URL",
        "valueFrom": "arn:aws:ssm:${local.region}:${local.account}:parameter/${var.env_name}/${var.app_name}/REDIS_URL"
          }
      ]
    }
  ])

  cpu          = var.ecs_task_cpu_api
  memory       = var.ecs_task_memory_hard_limit_api
  network_mode = "awsvpc"

  execution_role_arn       = aws_iam_role.ecsTaskExecutionRole.arn
  task_role_arn            = aws_iam_role.ecsTaskExecutionRole.arn

  requires_compatibilities = ["FARGATE"]
  
  lifecycle {
    ignore_changes = [container_definitions]
  }
}

resource "aws_ecs_task_definition" "task_worker" {
  family = "${local.environment}-worker"
  container_definitions = jsonencode([
    {
      "essential": true,
      "image": "${local.ecr_worker_repository_url}:${var.aws_ecr_image_tag}",
      "name": "${local.environment}-worker",
      "memoryReservation": var.ecs_task_memory_worker,
      "portMappings": [
      ],
      "logConfiguration": {
          "logDriver": "awslogs",
          "options": {
              "awslogs-group": "/ecs/${var.env_name}/${var.app_name}/worker",
              "awslogs-region": "${local.region}",
              "awslogs-stream-prefix": "ecs"
          }
      },
      "environment": [
                {
                    "name": "NODE_ENV",
                    "value": "production"
                }
            ],
      "secrets": [
        {
        "name": "FE_APP_URL",
        "valueFrom": "arn:aws:ssm:${local.region}:${local.account}:parameter/${var.env_name}/${var.app_name}/FE_APP_URL"
          },
        {
        "name": "FE_APP_API_KEY",
        "valueFrom": "arn:aws:ssm:${local.region}:${local.account}:parameter/${var.env_name}/${var.app_name}/FE_APP_API_KEY"
          },
        {
        "name": "MAO_API_BASE_URL",
        "valueFrom": "arn:aws:ssm:${local.region}:${local.account}:parameter/${var.env_name}/${var.app_name}/MAO_API_BASE_URL"
          },
        {
        "name": "MAO_API_API_KEY",
        "valueFrom": "arn:aws:ssm:${local.region}:${local.account}:parameter/${var.env_name}/${var.app_name}/MAO_API_API_KEY"
          },
        {
        "name": "OCS_API_BASE_URL",
        "valueFrom": "arn:aws:ssm:${local.region}:${local.account}:parameter/${var.env_name}/${var.app_name}/OCS_API_BASE_URL"
          },
        {
        "name": "OCS_API_API_KEY",
        "valueFrom": "arn:aws:ssm:${local.region}:${local.account}:parameter/${var.env_name}/${var.app_name}/OCS_API_API_KEY"
          },
        {
        "name": "REDIS_URL",
        "valueFrom": "arn:aws:ssm:${local.region}:${local.account}:parameter/${var.env_name}/${var.app_name}/REDIS_URLs"
          }
      ]
    }
  ])

  cpu          = var.ecs_task_cpu_worker
  memory       = var.ecs_task_memory_hard_limit_worker
  network_mode = "awsvpc"

  execution_role_arn       = aws_iam_role.ecsTaskExecutionRole.arn
  task_role_arn            = aws_iam_role.ecsTaskExecutionRole.arn

  requires_compatibilities = ["FARGATE"]
  
  lifecycle {
    ignore_changes = [container_definitions]
  }
}

data "aws_ecs_task_definition" "task_frontend" {
  task_definition = aws_ecs_task_definition.task_frontend.family
  depends_on      = [aws_ecs_task_definition.task_frontend]
}

data "aws_ecs_task_definition" "task_api" {
  task_definition = aws_ecs_task_definition.task_api.family
  depends_on      = [aws_ecs_task_definition.task_api]
}

data "aws_ecs_task_definition" "task_worker" {
  task_definition = aws_ecs_task_definition.task_worker.family
  depends_on      = [aws_ecs_task_definition.task_worker]
}

# Define the cluster and frontend/api/worker services 
resource "aws_ecs_cluster" "cluster" {
  name = "${local.environment}"
}

resource "aws_ecs_service" "app_frontend" {
  name    = "${local.environment}-frontend"
  cluster = aws_ecs_cluster.cluster.id

  # Track the latest ACTIVE revision
  task_definition = "${aws_ecs_task_definition.task_frontend.family}:${max("${aws_ecs_task_definition.task_frontend.revision}", "${data.aws_ecs_task_definition.task_frontend.revision}")}"
  launch_type     = "FARGATE"
  desired_count   = 1

  platform_version = "LATEST"

  network_configuration {
    assign_public_ip = false
    security_groups  = [aws_security_group.ecs_tasks.id]
    subnets          = local.private_subnet_ids
  }

  deployment_controller {
    type = "ECS"
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.frontend.arn
    container_name   = "${local.environment}-frontend"
    container_port   = 80
  }

  health_check_grace_period_seconds = 30

  # Optional: Allow external changes without Terraform plan difference
  lifecycle {
    ignore_changes = [desired_count, task_definition]
  }

  # workaround for https://github.com/hashicorp/terraform/issues/12634
  depends_on = [aws_alb_listener.https]

  tags = {}
}

resource "aws_ecs_service" "app_api" {
  name    = "${local.environment}-api"
  cluster = aws_ecs_cluster.cluster.id

  # Track the latest ACTIVE revision
  task_definition = "${aws_ecs_task_definition.task_api.family}:${max("${aws_ecs_task_definition.task_api.revision}", "${data.aws_ecs_task_definition.task_api.revision}")}"
  launch_type     = "FARGATE"
  desired_count   = 1

  platform_version = "LATEST"

  network_configuration {
    assign_public_ip = false
    security_groups  = [aws_security_group.ecs_tasks.id]
    subnets          = local.private_subnet_ids
  }

  deployment_controller {
    type = "ECS"
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.api.arn
    container_name   = "${local.environment}-api"
    container_port   = 3001
  }

  # Optional: Allow external changes without Terraform plan difference
  lifecycle {
    ignore_changes = [desired_count, task_definition]
  }

  # workaround for https://github.com/hashicorp/terraform/issues/12634
  depends_on = [aws_alb_listener.https] # depends_on = [aws_alb_listener.https]

  tags = {}
}

resource "aws_ecs_service" "app_worker" {
  name    = "${local.environment}-worker"
  cluster = aws_ecs_cluster.cluster.id

  # Track the latest ACTIVE revision
  task_definition = "${aws_ecs_task_definition.task_worker.family}:${max("${aws_ecs_task_definition.task_worker.revision}", "${data.aws_ecs_task_definition.task_worker.revision}")}"
  launch_type     = "FARGATE"
  desired_count   = 1

  platform_version = "LATEST"

  network_configuration {
    assign_public_ip = false
    security_groups  = [aws_security_group.ecs_tasks.id]
    subnets          = local.private_subnet_ids
  }

  deployment_controller {
    type = "ECS"
  }

  #load_balancer {
  #  target_group_arn = aws_lb_target_group.api.arn
  #  container_name   = "${local.environment}-api"
  #  container_port   = 3001
  #}

  # Optional: Allow external changes without Terraform plan difference
  lifecycle {
    ignore_changes = [desired_count, task_definition]
  }

  # workaround for https://github.com/hashicorp/terraform/issues/12634
  #depends_on = [aws_alb_listener.https] # depends_on = [aws_alb_listener.https]

  tags = {}
}

# https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_execution_IAM_role.html
resource "aws_iam_role" "ecsTaskExecutionRole" {
  name               = "${local.environment}-ecs"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
  permissions_boundary = var.permissions_boundary_arn
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "ecsTaskExecutionRole_policy" {
  role       = aws_iam_role.ecsTaskExecutionRole.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Add role policy for access to ssm parameters
resource "aws_iam_role_policy" "params" {
  name = "${local.environment}-params-policy"
  role = aws_iam_role.ecsTaskExecutionRole.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ssm:GetParameters"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:ssm:${local.region}:${local.account}:*"
    }
  ]
}
EOF
}