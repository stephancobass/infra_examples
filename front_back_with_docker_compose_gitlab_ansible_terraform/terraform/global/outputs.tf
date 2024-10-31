output "gitlab_oidc_role_arn" {
    value = aws_iam_role.gitlab_oidc_role.arn
}

output "key_pair_custom_name" {
    value = aws_key_pair.key_pair_custom.key_name
}