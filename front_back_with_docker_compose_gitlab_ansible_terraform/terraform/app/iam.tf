data aws_iam_policy_document "ec2_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ec2_iam_role" {
  name = "ec2_iam_role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json

  inline_policy {
    name = "s3_ecr_full_access_policy"
    policy = file("s3_ecr_iam_policy.json")

  }
}

resource "aws_iam_instance_profile" "app_instance_profile" {
  name = "app_instance_profile"
  role = aws_iam_role.ec2_iam_role.name
}