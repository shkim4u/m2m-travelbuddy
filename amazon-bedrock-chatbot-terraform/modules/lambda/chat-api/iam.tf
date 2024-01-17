resource "aws_iam_role" "chatbot_api_lambda_role" {
  name               = "amazon-bedrock-chatbot-api-lambda-role"
  path               = "/"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Sid       = ""
        Principal = {
          Service = ["lambda.amazonaws.com", "bedrock.amazonaws.com"]
        }
      },
    ]
  })

  inline_policy {
    name = "amazon-bedrock-chatbot-api-lambda-role-inline-policy"

    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action   = [
            "bedrock:*"
          ]
          Effect   = "Allow"
          Resource = "*"
        },
      ]
    })
  }
}

resource "aws_iam_role_policy_attachment" "chatbot_api_lambda_role_policy" {
  role = aws_iam_role.chatbot_api_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
