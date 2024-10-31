data "aws_partition" "current" {}

data "aws_region" "current" {}

data "tls_certificate" "gitlab" {
  url = var.gitlab_url
}

resource "aws_iam_openid_connect_provider" "gitlab_oidc" {
  url = var.gitlab_url
  client_id_list = [
    var.gitlab_url,
  ]

  thumbprint_list = [data.tls_certificate.gitlab.certificates.0.sha1_fingerprint]

  tags = {
      Name = "gitlab_oidc"
    }
}

data "aws_iam_policy_document" "assume-role-policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.gitlab_oidc.arn]
    }
    condition {
      test     = "StringEquals"
      variable = "${aws_iam_openid_connect_provider.gitlab_oidc.url}:${var.match_field}"
      values   = var.match_value
    }
  }
}

resource "aws_iam_role" "gitlab_oidc_role" {
  name               = "gitlab_oidc_role"
  description        = "gitlab_oidc_role"
  path               = "/ci/"
  assume_role_policy = data.aws_iam_policy_document.assume-role-policy.json

  inline_policy {
    name = "gitlab_oidc_policy"

    policy = file("oidc_custom_policy.json")

  }

}