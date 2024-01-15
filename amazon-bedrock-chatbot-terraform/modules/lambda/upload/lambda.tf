module "lambda_upload" {
  source = "terraform-aws-modules/lambda/aws"

  function_name = local.lambda_function_name
  description   = "Amazon Bedrock Chatbot Upload Lambda function"
  source_path = "${path.module}/lambda-function"
  handler = "index.handler"
  architectures = ["x86_64"]
  runtime = "nodejs16.x"
  timeout = 60

  cloudwatch_logs_retention_in_days = 7

  environment_variables = {
    bucketName = var.bucket_name
    s3_prefix = var.s3_prefix
  }
}
