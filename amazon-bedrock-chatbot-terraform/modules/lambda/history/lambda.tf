module "lambda_history" {
  source = "terraform-aws-modules/lambda/aws"

  function_name = local.lambda_function_name
  description   = "Amazon Bedrock Chatbot History Lambda function"
  source_path = "${path.module}/lambda-function"
  handler = "index.handler"
  architectures = ["x86_64"]
  runtime = "nodejs16.x"
  timeout = 60

  cloudwatch_logs_retention_in_days = 7

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
      }
    ]
  })

  attach_policy = true
  policy = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"

  environment_variables = {
    tableName = var.call_log_table_name
  }
}

resource "aws_lambda_permission" "allow_api_gateway" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda_history.lambda_function_name
  principal     = "apigateway.amazonaws.com"
}
