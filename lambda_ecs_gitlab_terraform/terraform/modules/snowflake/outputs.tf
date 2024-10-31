
output "snowflake_house_db" {
  value = snowflake_database.snowflake_house_db
}

output "landing_schema" {
  value = snowflake_schema.landing_schema
}

output "s3_root_stage" {
  value = snowflake_stage.s3_root_stage
}

output "landing_files" {
  value = snowflake_table.landing_files
}

output "parquet" {
  value = snowflake_file_format.parquet
}

# output "stage_pipe" {
#   value = snowflake_pipe.stage_pipe
# }
