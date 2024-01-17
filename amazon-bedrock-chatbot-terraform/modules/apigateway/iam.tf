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
    name = "amazon-bedrock-chatbot-apigateway-role-inline-policy"

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
#  policy_arn = data.aws_iam_policy.lambda_execution_policy.arn
  policy_arn = "arn:aws:iam::aws:policy/AWSLambdaExecute"
}
