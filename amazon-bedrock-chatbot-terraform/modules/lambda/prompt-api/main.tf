module "lambda_prompt_api" {
  source = "terraform-aws-modules/lambda/aws"

  function_name = local.lambda_function_name
  description   = "Amazon Bedrock Prompt API Lambda function"
  source_path = "${path.module}/lambda-function"
  handler = "lambda_function.lambda_handler"
  architectures = ["x86_64"]
  runtime = local.python_runtime
  timeout = 300

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
        Action   = [
          "bedrock:*"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })

  attach_policy = true
  policy = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"

  environment_variables = {
    bedrock_region: var.bedrock_region,
    model_id: var.model_id
  }

  tracing_mode = "Active"
  attach_tracing_policy = true

  # Publish a new version of the Lambda function
  publish = true

  # Apply provisioned concurrency to the published version
  provisioned_concurrent_executions = 10

  # Add layers to the Lambda function.
  layers = var.layers
}

resource "aws_lambda_permission" "allow_api_gateway" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda_prompt_api.lambda_function_name
  principal     = "apigateway.amazonaws.com"
}

###
### Alias.
###
module "lambda_prompt_api_alias" {
  source = "terraform-aws-modules/lambda/aws//modules/alias"

  create        = true
  refresh_alias = true

  function_version = module.lambda_prompt_api.lambda_function_version

  name = "live"

  function_name = module.lambda_prompt_api.lambda_function_name
}
###
### End of Alias.
###
