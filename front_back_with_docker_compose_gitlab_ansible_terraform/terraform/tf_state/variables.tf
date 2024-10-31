variable "s3_tf_state_name" {
  type        = string
  default = "app-iac-terraform-state"
}
variable "dynamodb_tf_state_name" {
  type        = string
  default     = "app-iac-terraform-state-lock-dynamo"
}