resource "aws_sfn_state_machine" "telegram_lambda_sfn_state_machine" {
  name       = "${var.environment}-telegram-s3-lambda-sfn"
  role_arn   = aws_iam_role.step_function_role.arn
  definition = <<EOF
{
  "Comment": "Accessing context object in a state machine",
  "StartAt": "Get List of Entities",
  "States": {
    "Get List of Entities": {
      "Type": "Task",
      "Next": "Map",
      "Parameters": {
        "Bucket": "${var.aws_s3_bucket_name}",
        "Key": "telegram/entity_list.json"
      },
      "Resource": "arn:aws:states:::aws-sdk:s3:getObject",
      "ResultSelector": {
        "accounts_list.$": "States.StringToJson($.Body)"
      }
    },
    "Map": {
      "Type": "Map",
      "ItemProcessor": {
        "ProcessorConfig": {
          "Mode": "INLINE"
        },
        "StartAt": "Convert array input into JSON",
        "States": {
          "Convert array input into JSON": {
            "Type": "Pass",
            "Next": "Get Timestamp",
            "Parameters": {
              "channel_name.$": "$"
            }
          },
          "Get Timestamp": {
            "Type": "Task",
            "Parameters": {
              "Bucket": "${var.aws_s3_bucket_name}",
              "Key.$": "States.Format('telegram/{}/config.json', $.channel_name)"
            },
            "Resource": "arn:aws:states:::aws-sdk:s3:getObject",
            "Catch": [
              {
                "ErrorEquals": [
                  "States.TaskFailed"
                ],
                "Comment": "On Access error",
                "Next": "Initial lambda call for account",
                "ResultPath": "$.Error"
              }
            ],
            "Next": "Delta Lambda Invoke",
            "ResultSelector": {
              "config.$": "States.StringToJson($.Body)"
            }
          },
          "Initial lambda call for account": {
            "Type": "Task",
            "Resource": "arn:aws:states:::lambda:invoke",
            "OutputPath": "$.Payload",
            "Parameters": {
              "FunctionName": "${aws_lambda_function.telegram_s3_lambda.arn}",
              "Payload": {
                "ProcessingMethod": "POST",
                "StartTimestamp": "2023-02-01T08:00:00.000000Z",
                "EndTimestamp.$": "$$.Execution.StartTime",
                "ChannelName.$": "$.channel_name"
              }
            },
            "Retry": [
              {
                "ErrorEquals": [
                  "Lambda.ServiceException",
                  "Lambda.AWSLambdaException",
                  "Lambda.SdkClientException",
                  "Lambda.TooManyRequestsException"
                ],
                "IntervalSeconds": 2,
                "MaxAttempts": 6,
                "BackoffRate": 2
              }
            ],
            "Next": "Convert lambda output to JSON"
          },
          "Delta Lambda Invoke": {
            "Type": "Task",
            "Resource": "arn:aws:states:::lambda:invoke",
            "OutputPath": "$.Payload",
            "Parameters": {
              "FunctionName": "${aws_lambda_function.telegram_s3_lambda.arn}",
              "Payload": {
                "ProcessingMethod": "POST",
                "StartTimestamp.$": "$.config.last_load_timestamp",
                "EndTimestamp.$": "$$.Execution.StartTime",
                "ChannelName.$": "$.config.channel_name"
              }
            },
            "Retry": [
              {
                "ErrorEquals": [
                  "Lambda.ServiceException",
                  "Lambda.AWSLambdaException",
                  "Lambda.SdkClientException",
                  "Lambda.TooManyRequestsException"
                ],
                "IntervalSeconds": 2,
                "MaxAttempts": 6,
                "BackoffRate": 2
              }
            ],
            "Next": "Convert lambda output to JSON"
          },
          "Convert lambda output to JSON": {
            "Type": "Pass",
            "Next": "Check if Lambda finished successfully",
            "Parameters": {
              "response.$": "States.StringToJson($)"
            }
          },
          "Check if Lambda finished successfully": {
            "Type": "Choice",
            "Choices": [
              {
                "Variable": "$.upload_result",
                "BooleanEquals": true,
                "Next": "Update/Create config.json"
              }
            ],
            "Default": "Raise exception",
            "InputPath": "$.response"
          },
          "Raise exception": {
            "Type": "Pass",
            "End": true,
            "Result": {
              "NO_EXISTING_KEY.$": "$.NO_EXISTING_KEY"
            }
          },
          "Update/Create config.json": {
            "Type": "Task",
            "Parameters": {
              "Body": {
                "channel_name.$": "$.channel_name",
                "channel_id.$": "$.channel_id",
                "last_load_timestamp.$": "$$.Execution.StartTime"
              },
              "Bucket": "${var.aws_s3_bucket_name}",
              "Key.$": "States.Format('telegram/{}/config.json', $.channel_name)"
            },
            "Resource": "arn:aws:states:::aws-sdk:s3:putObject",
            "End": true,
            "Retry": [
              {
                "ErrorEquals": [
                  "States.TaskFailed"
                ],
                "BackoffRate": 1,
                "IntervalSeconds": 900,
                "MaxAttempts": 2,
                "Comment": "Retry PutObject"
              }
            ]
          }
        }
      },
      "End": true,
      "ItemsPath": "$.accounts_list.channel_list",
      "MaxConcurrency": 1
    }
  }
}
EOF
}