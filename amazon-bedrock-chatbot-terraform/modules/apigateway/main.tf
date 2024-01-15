resource "aws_iam_role" "apigateway_role" {
  name               = "amazon-bedrock-chatbot-apigateway-role"
  path               = "/"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Sid       = ""
        Principal = {
          Service = "apigateway.amazonaws.com"
        }
      },
    ]
  })

  inline_policy {
    name = "eks-full-access-policy"

    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action   = [
            "lambda:InvokeFunction",
            "cloudwatch:*"
          ]
          Effect   = "Allow"
          Resource = "*"
        },
      ]
    })
  }
}

resource "aws_iam_role_policy_attachment" "apigatway_role_policy" {
  role = aws_iam_role.apigateway_role.name
  policy_arn = data.aws_iam_policy.lambda_execution_policy.arn
}

module "apigateway_rest" {
  source = "./rest"
  chat_api_lambda_function_invoke_arn = var.chat_api_lambda_function_invoke_arn
  upload_lambda_function_invoke_arn = var.upload_lambda_function_invoke_arn
  query_result_lambda_function_invoke_arn = var.query_result_lambda_function_invoke_arn
  history_lambda_function_invoke_arn = var.history_lambda_function_invoke_arn
  delete_log_lambda_function_invoke_arn = var.delete_log_lambda_function_invoke_arn
  role_arn = aws_iam_role.apigateway_role.arn
}

module "apigateway_ws" {
  source = "./ws"
  chat_ws_lambda_function_invoke_arn = var.chat_ws_lambda_function_invoke_arn
  role_arn = aws_iam_role.apigateway_role.arn
}
