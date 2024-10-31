terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.48.0"
    }
  }
}

resource "aws_ecs_cluster" "dbt_fargate_cluster" {
  name = "sh-dbt-${var.environment}-fargate-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_ecs_cluster_capacity_providers" "dbt_cluster_fargate_provider" {
  cluster_name       = aws_ecs_cluster.dbt_fargate_cluster.name
  capacity_providers = ["FARGATE"]
}

data "aws_iam_policy_document" "ecs_tasks_assume_role_trusted_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

data "aws_iam_policy" "amazon_ecs_task_execution_role_policy" {
  name = "AmazonECSTaskExecutionRolePolicy"
}

# TODO
data "aws_iam_policy" "custom_access_to_secrets_policy" {
  name = "SnowflakeHouseFullAccessPolicy"
}

resource "aws_iam_role" "ecs_tasks_execution_role" {
  name               = "sh-${var.environment}-ecsTaskExecutionRole"
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_assume_role_trusted_policy.json
}

resource "aws_iam_role_policy_attachment" "ecs_tasks_execution_role" {
  role       = aws_iam_role.ecs_tasks_execution_role.name
  policy_arn = data.aws_iam_policy.amazon_ecs_task_execution_role_policy.arn
}

resource "aws_iam_role_policy_attachment" "ecs_tasks_execution_role_secrets_access_policy" {
  role       = aws_iam_role.ecs_tasks_execution_role.name
  policy_arn = data.aws_iam_policy.custom_access_to_secrets_policy.arn
}

resource "aws_cloudwatch_log_group" "dbt_group" {
  name              = "/snowflake-house/${var.environment}/dbt"
  retention_in_days = 3
}

resource "aws_ecs_task_definition" "dbt_task" {
  family                   = "sh-${var.environment}-dbt-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  execution_role_arn       = aws_iam_role.ecs_tasks_execution_role.arn
  cpu                      = 256
  memory                   = 512
  container_definitions = jsonencode([
    {
      name   = "sh-${var.environment}-dbt-container"
      image  = "${var.aws_account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/sh-${var.environment}-dbt-repo:latest"
      cpu    = 256
      memory = 512
      essential = true
      portMappings = [
        {
          containerPort = 8080
          hostPort      = 8080
        }
      ]

      environment = [
        {
          "name": "ENVIRONMENT",
          "value": "${var.environment}"
        },
        {
          "name": "SNOWFLAKE_ACCOUNT",
          "value": "${var.snowflake_account}"
        },
        {
          "name": "SNOWFLAKE_USER",
          "value": "${var.snowflake_user}"
        },
        {
          "name": "SNOWFLAKE_PASSWORD",
          "value": "${var.snowflake_password}"
        },
        {
          "name": "SNOWFLAKE_ROLE",
          "value": "${var.snowflake_role}"
        },
        {
          "name": "SNOWFLAKE_REGION",
          "value": "${var.snowflake_region}"
        },
        {
          "name": "SNOWFLAKE_WAREHOUSE",
          "value": "${var.snowflake_warehouse}"
        },
        {
          "name": "SNOWFLAKE_DATABASE",
          "value": "${var.snowflake_database}"
        }
        
      ]

      
      logConfiguration = {
        "logDriver" : "awslogs",
        "options" : {
          "awslogs-group" : "${aws_cloudwatch_log_group.dbt_group.name}",
          "awslogs-region" : "us-west-2",
          "awslogs-stream-prefix" : "ecs"
        }
      }
    }
  ])
  
}

# Used for Step Functions to run ECS Task
data "aws_iam_policy_document" "states_and_events_assume_role_trusted_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["states.amazonaws.com"]
    }
  }

  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "step_function_run_ecs_task_role" {
  name               = "sh-${var.environment}-StepFunctionRunECSTaskRole"
  assume_role_policy = data.aws_iam_policy_document.states_and_events_assume_role_trusted_policy.json
}

resource "aws_iam_role_policy_attachment" "p1" {
  role       = aws_iam_role.step_function_run_ecs_task_role.name
  policy_arn = "arn:aws:iam::521213957793:policy/service-role/CloudWatchLogsDeliveryFullAccessPolicy-9b01e4fe-afb6-4009-b375-929480e85784"
}

resource "aws_iam_role_policy_attachment" "p2" {
  role       = aws_iam_role.step_function_run_ecs_task_role.name
  policy_arn = "arn:aws:iam::521213957793:policy/snowflake-house-loc-rs-step-functions-run-ecs-policy"
}

resource "aws_iam_role_policy_attachment" "p3" {
  role       = aws_iam_role.step_function_run_ecs_task_role.name
  policy_arn = "arn:aws:iam::521213957793:policy/service-role/XRayAccessPolicy-e8cc0930-3570-4591-8ed5-a49bc300347b"
}

resource "aws_sfn_state_machine" "run_ecs_dbt_task_state_machine" {
  name     = "sh-${var.environment}-run_ecs_dbt_task"
  role_arn = aws_iam_role.step_function_run_ecs_task_role.arn

  definition = jsonencode(
    {
      "Comment" : "Executes ECS Task that contains dbt project.",
      "StartAt" : "ECS RunTask",
      "States" : {
        "ECS RunTask" : {
          "Type" : "Task",
          "Resource" : "arn:aws:states:::ecs:runTask.sync",
          "Parameters" : {
            "LaunchType" : "FARGATE",
            "Cluster" : "${aws_ecs_cluster.dbt_fargate_cluster.arn}",
            "TaskDefinition" : "${aws_ecs_task_definition.dbt_task.arn}",
            "NetworkConfiguration" : {
              "AwsvpcConfiguration" : {
                "Subnets" : [
                  # TODO
                  "subnet-73a65e38"
                ],
                "AssignPublicIp" : "ENABLED"
              }
            },
            "Overrides" : {
              "ContainerOverrides" : [
                {
                  "Name" : "sh-${var.environment}-dbt-container",
                  "Command.$" : "$.commands"
                }
              ]
            }
          },
          "End" : true
        }
      }
    }
  )

  logging_configuration {
    log_destination        = "${aws_cloudwatch_log_group.dbt_group.arn}:*"
    include_execution_data = true
    level                  = "ALL"
  }
}

# Used for Scheduler
data "aws_iam_policy_document" "scheduler_assume_role_trusted_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["scheduler.amazonaws.com"]
    }
    
    condition {
      test     = "ForAnyValue:StringEquals"
      variable = "aws:SourceArn"
      values   = ["arn:aws:scheduler:us-west-2:521213957793:schedule/default/sh-${var.environment}-run_dbt"]
    }
    
    condition {
      test     = "ForAnyValue:StringEquals"
      variable = "aws:SourceAccount"
      values   = ["521213957793"]
    }
  }
}

resource "aws_iam_role" "scheduler_role" {
  name               = "sh-${var.environment}-EventBridgeSchedulerRole"
  assume_role_policy = data.aws_iam_policy_document.scheduler_assume_role_trusted_policy.json
}

resource "aws_iam_policy" "scheduler_execute_step_function_policy" {
  name        = "sh-${var.environment}-EventBridgeScheduler-StepFunction-Execution-Policy"
  path        = "/"
  description = "Policy to execute Step Function from Event Bridge Scheduler"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["states:StartExecution"]
        Effect   = "Allow"
        Resource = [
          aws_sfn_state_machine.run_ecs_dbt_task_state_machine.arn
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "scheduler_role_execute_step_function" {
  role       = aws_iam_role.scheduler_role.name
  policy_arn = aws_iam_policy.scheduler_execute_step_function_policy.arn
}

resource "aws_scheduler_schedule" "dbt_daily" {
  name       = "sh-${var.environment}-run_dbt"

  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression = "cron(30 2 ? * * *)"
  schedule_expression_timezone = "UTC"

  target {
    arn      = aws_sfn_state_machine.run_ecs_dbt_task_state_machine.arn
    role_arn = aws_iam_role.scheduler_role.arn

    input    = jsonencode(
      {
        "commands": ["dbt", "run"]
      }
    )

    retry_policy {
      maximum_retry_attempts = 0  # OFF
    }
  }
}
