# Additional Gitlab CI variables for IODC connect

## AWS_CONFIG_FILE 
type - file
value:
[profile gitlab_oidc]
role_arn=${GITLAB_OIDC_ROLE_ARN}
web_identity_token_file=${web_identity_token}

## AWS_DEFAULT_REGION - ap-southeast-2
## AWS_PROFILE - gitlab_oidc
## GITLAB_OIDC_ROLE_ARN

## web_identity_token
type - file
value:  ${GITLAB_OIDC_TOKEN}