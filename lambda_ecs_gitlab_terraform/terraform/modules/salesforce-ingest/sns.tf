resource "aws_sns_topic" "salesforce" {
  name = "Salesforce"
}

resource "aws_sns_topic_policy" "publish" {
  arn = aws_sns_topic.salesforce.arn
  policy = templatefile("sns_topic_policy.json", {
    tf_topic = aws_sns_topic.salesforce.arn
  })

}
