variable "s3_tf_state_name" {
    default = "app-iac-terraform-state"
}
variable "dynamodb_tf_state_name" {
    default = "app-terraform-state-lock-dynamo"
}