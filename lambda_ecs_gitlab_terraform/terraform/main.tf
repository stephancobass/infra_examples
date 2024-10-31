terraform {
  # required_version = ">= 1.1.7"

  required_providers {
    gitlab = {
      source  = "gitlabhq/gitlab"
      version = "~> 15.7.1"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.48.0"
    }
    snowflake = {
      source  = "Snowflake-Labs/snowflake"
      version = "~> 0.54.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.9"
    }
  }
}

module "dbt" {
  source      = "./modules/dbt/"
  environment = var.environment
  aws_account_id = var.aws_account_id
  aws_region = var.aws_region
  snowflake_account = var.snowflake_account
  snowflake_user = var.snowflake_user
  snowflake_password = var.snowflake_password
  snowflake_role = var.snowflake_role
  snowflake_region = var.snowflake_region
  snowflake_warehouse = var.snowflake_warehouse
  snowflake_database = var.snowflake_database
}

module "telegram_s3_lambda" {
  source = "./modules/telegram-s3-lambda/"
  environment = var.environment
  aws_s3_bucket_name = var.aws_s3_bucket_name
  aws_region = var.aws_region
  telegram_secret_value = var.telegram_secret_value
  default_telegram_timestamp_format = var.default_telegram_timestamp_format
  default_telegram_channels_list = var.default_telegram_channels_list
  depends_on = [
    module.dbt
  ]

}

module "twitter_s3_lambda" {
  source = "./modules/twitter-s3-lambda/"
  environment = var.environment
  aws_s3_bucket_name = var.aws_s3_bucket_name
  aws_region = var.aws_region
  data_compute_layer_arn = module.telegram_s3_lambda.data_compute_layer_arn
  twitter_secret_value = var.twitter_secret_value
  twitter_fields = var.twitter_fields
  depends_on = [
    module.dbt
  ]

}

/*
module "salesforce_ingest" {
  source = "./modules/salesforce-ingest/"
  environment = var.environment
  aws_s3_bucket_name = module.aws_s3.data_bucket.bucket
  aws_region = var.aws_region
  data_compute_layer_arn = module.telegram_s3_lambda.data_compute_layer_arn
  twitter_secret_value = var.twitter_secret_value
  twitter_secret_name = var.twitter_secret_name
  twitter_fields = var.twitter_fields
  depends_on = [
    module.dbt
  ]
}
*/

module "storage_integration" {
  source             = "./modules/storage_integration/"
  aws_account_id     = var.aws_account_id
  aws_s3_bucket_name = var.aws_s3_bucket_name

  aws_iam_snowflake_si_policy = var.aws_iam_snowflake_si_policy
  aws_iam_snowflake_si_role   = var.aws_iam_snowflake_si_role
  
  snowflake_storage_integration_name  = var.snowflake_storage_integration_name
}

module "snowflake_database" {
  source                    = "./modules/snowflake/"
  snowflake_account         = var.snowflake_account
  snowflake_database        = var.snowflake_database
  aws_s3_bucket_name                  = var.aws_s3_bucket_name
  # aws_sns_s3_pipe_topic_arn           = module.aws_s3.data_bucket_notification.arn
  snowflake_storage_integration_name  = module.storage_integration.sf_aws_integration.name

  depends_on = [
    module.storage_integration.sf_aws_integration
  ]
}

resource "time_sleep" "wait_15_seconds" {
  create_duration = "15s"
  depends_on = [
    module.snowflake_database.landing_files,
    module.snowflake_database.s3_root_stage,
    module.snowflake_database.parquet,
    module.storage_integration.sf_aws_integration
  ]
}

resource "snowflake_pipe" "stage_pipe" {
  database = module.snowflake_database.landing_schema.database
  schema   = module.snowflake_database.landing_schema.name
  name     = "STAGE_PIPE"
  comment  = "A pipe that grabs files from S3 into Snowflake table STAGING.STAGE_FILES."
  
  auto_ingest    = true
  copy_statement = <<-EOT
    COPY INTO ${module.snowflake_database.landing_files.database}.${module.snowflake_database.landing_files.schema}.${module.snowflake_database.landing_files.name}
    FROM (
      SELECT
        $1::VARIANT AS ROW_VALUES,
        METADATA$FILENAME::VARCHAR AS SRC_FILE_NAME,
        METADATA$FILE_ROW_NUMBER::NUMBER AS SRC_FILE_ROW_NUMBER,
        CAST(CURRENT_TIMESTAMP() AS TIMESTAMP_TZ(9)) AS CREATED_TS
      FROM @${module.snowflake_database.s3_root_stage.database}.${module.snowflake_database.s3_root_stage.schema}.${module.snowflake_database.s3_root_stage.name}
      ( FILE_FORMAT => '${module.snowflake_database.parquet.database}.${module.snowflake_database.parquet.schema}.${module.snowflake_database.parquet.name}' )
    )
    ON_ERROR = CONTINUE
EOT

  depends_on = [
    time_sleep.wait_15_seconds
  ]
  # aws_sns_topic_arn = var.aws_sns_s3_pipe_topic_arn
  # notification_channel = "..."
}

resource "aws_s3_bucket_notification" "data_bucket_notification" {
  bucket = var.aws_s3_bucket_name

  queue {
    queue_arn     = snowflake_pipe.stage_pipe.notification_channel
    events        = ["s3:ObjectCreated:*"]
    #filter_prefix = "data/"
  }

  depends_on = [
    snowflake_pipe.stage_pipe
  ]
}
