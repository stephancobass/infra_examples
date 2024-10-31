variable "app_name"   {
  type = string
  default = "app"
}

variable "ecr_image_count" { 
  type        = string
  default = 5
}

variable "s3_backups" { 
  type        = string
  default = "app-backups"
}

variable "s3_data" { 
  type        = string
  default = "app-data"
}

variable "aws_key_name" {
  type        = string
  default     = "app_instance"
}

variable "gitlab_url" {
  type        = string
  default     = "https://gitlab.com"
}

variable "audiences_value" {
  type        = string
  default     = "https://gitlab.com"
}
variable "match_value" {
  type        = list(any)
  default =  [ "https://gitlab.com" ] #[ "project_path:app-developers/app/app-backend:ref_type:branch:ref:*" ]
  description = "GitLab match_value" 
}

variable "match_field" {
  type        = string
  default     = "aud"
  description = "GitLab match_field"
}

