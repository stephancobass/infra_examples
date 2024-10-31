# ECS Fargate requires to specify exect amount of memory available for the choosen vCPU
# https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definition_parameters.html#container_definition_memory

variable "app_name" {}
variable "env_name" {}
variable "aws_ecr_image_tag"  {}

# CPU units
# .25 vCPU = 256 CPU units, MiB
variable "ecs_task_cpu_frontend" { default = 256 }
variable "ecs_task_memory_frontend" { default = 512 }
variable "ecs_task_memory_hard_limit_frontend" { default = 1024 }

#.5 vCPU = 512 CPU units, MiB
# Set api container
variable "ecs_task_cpu_api" { default = 256 }
variable "ecs_task_memory_api" { default = 512 }
variable "ecs_task_memory_hard_limit_api" { default = 1024 }

# Set worker container
variable "ecs_task_cpu_worker" { default = 256 }
variable "ecs_task_memory_worker" { default = 512 }
variable "ecs_task_memory_hard_limit_worker" { default = 1024 }

# ARN of IAM permissions boundary policy
variable "permissions_boundary_arn" {
    default = "arn:aws:iam::123456789012:policy/custome-policy"
}


# For Roure53
variable "domain_name_zone" {}


### Cloudwatch variables
# Set log retain period for log groups
variable "logs_retention_in_days" {
  type        = number
  default     = 30
  description = "Specifies the number of days you want to retain log events"
}

# Set variables for alarms
# SNS variables
variable "cloudwatch_alarm_email" {
    default = "app@example.com"
}