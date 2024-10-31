
provider "gitlab" {
  token = var.gitlab_access_token
}

provider "aws" {
}

provider "snowflake" {
  username = var.snowflake_user
  account = var.snowflake_account
}
