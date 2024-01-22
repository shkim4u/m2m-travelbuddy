module "lambda_simple_ws" {
  source = "terraform-aws-modules/lambda/aws"

  function_name = "amazon-bedrock-simple-ws"
  description   = "Amazon Bedrock Simple WebSocket API Lambda function"

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
        "Action": [
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
#    connection_url: "https://8v6stbcr09.execute-api.ap-northeast-2.amazonaws.com/dev"
    connection_url: var.https_connection_url
  }

  depends_on = [null_resource.build_push_dkr_img, aws_ecr_repository.this]
}

resource "aws_lambda_permission" "allow_api_gateway" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda_simple_ws.lambda_function_name
  principal     = "apigateway.amazonaws.com"
}
