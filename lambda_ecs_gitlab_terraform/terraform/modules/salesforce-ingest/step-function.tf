resource "aws_sfn_state_machine" "salesforce_machine" {
  name     = "Salesforce"
  role_arn = aws_iam_role.sf_ingest_stepfunction_role.arn
  type     = "STANDARD"

  definition = templatefile("step-function.json", {
    tf_lambda = aws_lambda_function.sf_lambda.arn
    tf_key    = var.entity_key
    tf_topic  = aws_sns_topic.salesforce.arn
  })
}
