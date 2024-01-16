module "cloudfront" {
  source = "./modules/cloudfront"
  bucket_name = "${var.project_name}-${data.aws_region.current.name}-${data.aws_caller_identity.current.account_id}"
  wss_connection_url = module.apigateway.wss_connection_url
}

module "dynamodb" {
  source = "./modules/dynamodb"
}

module "lambda" {
  source = "./modules/lambda"
  s3_bucket_name = module.cloudfront.s3_bucket_name
  call_log_table_name = module.dynamodb.call_log_table_name
  call_log_index_name = module.dynamodb.call_log_table_name
  wss_connection_url = module.apigateway.wss_connection_url
  https_connection_url = module.apigateway.https_connection_url
}

module "apigateway" {
  source = "./modules/apigateway"
  chat_api_lambda_function_invoke_arn = module.lambda.chat_api_lambda_function_invoke_arn
  upload_lambda_function_invoke_arn = module.lambda.upload_lambda_function_invoke_arn
  query_result_lambda_function_invoke_arn = module.lambda.query_result_lambda_function_invoke_arn
  history_lambda_function_invoke_arn = module.lambda.history_lambda_function_invoke_arn
  delete_log_lambda_function_invoke_arn = module.lambda.delete_log_lambda_function_invoke_arn
  # Function ARN for WebSocket API
  chat_ws_lambda_function_invoke_arn = module.lambda.chat_ws_lambda_function_invoke_arn
}
