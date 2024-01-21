locals {
  bedrock_region = var.bedrock_region
  model_id = var.model_id
}

module "lambda_chat_ws" {
  source = "terraform-aws-modules/lambda/aws"

  function_name = "amazon-bedrock-chatbot-ws"
  description   = "Amazon Bedrock Chatbot WebSocket API Lambda function"

  create_package = false

  timeout = 300
  package_type = "Image"
  architectures = ["x86_64"]
  memory_size = 512

  image_uri = format("%v/%v:%v", local.ecr_reg, local.ecr_repo, local.image_tag)

  # Terraform Lambda module creates a role by default.
  # Following additional policies will be attached to that role.
  ######################
  # Additional policies
  ######################
  attach_policy_json = true
  policy_json = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = [
          "bedrock:*"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "s3:GetBucket*",
          "s3:GetObject*",
          "s3:List*"
        ]
        Effect   = "Allow"
        Resource = [
          "arn:aws:s3:::${var.s3_bucket_name}",
          "arn:aws:s3:::${var.s3_bucket_name}/*"
        ]
      },
      {
        "Action": [
          "dynamodb:BatchGetItem",
          "dynamodb:BatchWriteItem",
          "dynamodb:ConditionCheckItem",
          "dynamodb:DeleteItem",
          "dynamodb:DescribeTable",
          "dynamodb:GetItem",
          "dynamodb:GetRecords",
          "dynamodb:GetShardIterator",
          "dynamodb:PutItem",
          "dynamodb:Query",
          "dynamodb:Scan",
          "dynamodb:UpdateItem"
        ],
        "Resource": [
          "arn:aws:dynamodb:${data.aws_region.current.name}:${data.aws_caller_identity.this.account_id}:table/${var.call_log_table_name}",
          "arn:aws:dynamodb:${data.aws_region.current.name}:${data.aws_caller_identity.this.account_id}:table/${var.call_log_table_name}/index/*"
        ],
        "Effect": "Allow"
      },
      {
        "Action": [
#          "execute-api:Invoke",
#          "execute-api:ManageConnections"
          "execute-api:*"
        ],
        "Effect": "Allow"
        "Resource": "*"
      },
    ]
  })

  attach_policy = true
  policy = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"

  environment_variables = {
    bedrock_region: local.bedrock_region,
    model_id: local.model_id,
    s3_bucket: var.s3_bucket_name,
    s3_prefix: var.s3_prefix,
    callLogTableName: var.call_log_table_name,
    conversationMode: true,
    connection_url: var.https_connection_url
  }

  tracing_mode = "Active"
  attach_tracing_policy = true

  depends_on = [null_resource.build_push_dkr_img, aws_ecr_repository.this]
}

resource "aws_lambda_permission" "allow_api_gateway" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda_chat_ws.lambda_function_name
  principal     = "apigateway.amazonaws.com"
}
