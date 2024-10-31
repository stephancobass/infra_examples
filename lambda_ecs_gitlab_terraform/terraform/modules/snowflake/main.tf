terraform {
  required_providers {
    snowflake = {
      source  = "Snowflake-Labs/snowflake"
      version = "~> 0.54.0"
    }
  }
}

resource "snowflake_database" "snowflake_house_db" {
  name = var.snowflake_database
  }

resource "snowflake_schema" "landing_schema" {
  database = snowflake_database.snowflake_house_db.name
  name     = "LANDING"
  comment  = "A landing layer; used for uploading data from storage"
}

resource "snowflake_stage" "s3_root_stage" {
  name        = "S3_ROOT_STAGE"
  database    = snowflake_schema.landing_schema.database
  schema      = snowflake_schema.landing_schema.name
  url         = "s3://${var.aws_s3_bucket_name}/"
  storage_integration = var.snowflake_storage_integration_name
  comment     = "Reference to S3 bucket via storage integration"
}

resource "snowflake_table" "landing_files" {
  database            = snowflake_schema.landing_schema.database
  schema              = snowflake_schema.landing_schema.name
  name                = "LANDING_FILES"
  comment             = "A table that contains row as a JSON for all possible source files."
  cluster_by          = ["TO_DATE(CREATED_TS)"]

  column {
    name    = "ROW_VALUES"
    type    = "VARIANT"
    comment = "Object with all columns for a row"
  }

  column {
    name    = "SRC_FILE_NAME"
    type    = "VARCHAR"
    comment = "File name of the source file. From Stage METADATA"
  }

  column {
    name    = "SRC_FILE_ROW_NUMBER"
    type    = "NUMBER(38,0)"
    comment = "Record number within a source file. From Stage METADATA"
  }

  column {
    name = "CREATED_TS"
    type = "TIMESTAMP_TZ(9)"
    default {
      expression = "CAST(CURRENT_TIMESTAMP() AS TIMESTAMP_TZ(9))"
    }
  }

}

resource "snowflake_file_format" "parquet" {
  name        = "PARQUET"
  database    = snowflake_schema.landing_schema.database
  schema      = snowflake_schema.landing_schema.name
  format_type = "PARQUET"
  compression = "AUTO"
}


# resource "snowflake_table" "demo_table" {
#   database            = snowflake_schema.staging_schema.database
#   schema              = snowflake_schema.staging_schema.name
#   name                = "DEMO_TABLE"
#   comment             = "A table."
#   cluster_by          = ["TO_DATE(DATE)"]
#   data_retention_days = snowflake_schema.staging_schema.data_retention_days
#   change_tracking     = false

#   column {
#     name     = "ID"
#     type     = "NUMBER(38,0)"
#     nullable = false

#     identity {
#       start_num = 1
#       step_num  = 1
#     }
#   }

#   column {
#     name     = "DATA"
#     type     = "text"
#   }

#   column {
#     name    = "EXTRA"
#     type    = "VARIANT"
#     comment = "extra data"
#   }

#   column {
#     name = "CREATED_AT"
#     type = "TIMESTAMP_NTZ(9)"
#     # default {
#     #   expression = "CURRENT_TIMESTAMP()"
#     # }
#   }

# }

#region Skip

# resource "snowflake_role" "snowflake_house_role" {
#   name    = "SNOWFLAKE_HOUSE_ROLE"
# }

# resource "snowflake_account_grant" "role_create_db" {
#   roles                  = [ snowflake_role.snowflake_house_role.name ]
#   privilege              = "CREATE DATABASE"
#   with_grant_option      = false
#   enable_multiple_grants = false
# }

# resource "snowflake_warehouse" "compute_wh" {
#   name              = "COMPUTE_WH"
#   auto_resume       = true
#   auto_suspend      = 180
#   min_cluster_count = 1
#   max_cluster_count = 1
#   scaling_policy    = "ECONOMY"
#   warehouse_size    = "X-Small"
#   warehouse_type    = "STANDARD"
# }

# resource "snowflake_warehouse_grant" "usage" {
#   warehouse_name         = snowflake_warehouse.compute_wh.name
#   privilege              = "USAGE"
#   roles                  = [ snowflake_role.snowflake_house_role.name ]
#   with_grant_option      = false
#   enable_multiple_grants = false
# }


# resource "snowflake_storage_integration" "aws_s3_integration" {
#   name    = "AWS_S3_SH_SI"
#   comment = "AWS S3 storage integration for Snowflake House Project."
#   type    = "EXTERNAL_STAGE"
#   enabled = true

#   storage_allowed_locations = [ var.aws_s3_bucket_name ]
#   #   storage_blocked_locations = [""]
#   storage_aws_object_acl    = "bucket-owner-full-control"

#   storage_provider         = "S3"
#   # storage_aws_external_id  = "..."
#   storage_aws_iam_user_arn = "..."
#   storage_aws_role_arn     = "..."

#   # azure_tenant_id
# }

#endregion
