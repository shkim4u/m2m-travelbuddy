module "apigateway_rest" {
  source = "./rest"
  chat_api_lambda_function_invoke_arn = var.chat_api_lambda_function_invoke_arn
  chat_api_lambda_function_name = var.chat_api_lambda_function_name
  upload_lambda_function_invoke_arn = var.upload_lambda_function_invoke_arn
  upload_lambda_function_name = var.upload_lambda_function_name
  query_result_lambda_function_invoke_arn = var.query_result_lambda_function_invoke_arn
  query_result_lambda_function_name= var.query_result_lambda_function_name
  history_lambda_function_invoke_arn = var.history_lambda_function_invoke_arn
  history_lambda_function_name = var.history_lambda_function_name
  delete_log_lambda_function_invoke_arn = var.delete_log_lambda_function_invoke_arn
  delete_log_lambda_function_name = var.delete_log_lambda_function_name
  role_arn = aws_iam_role.apigateway_role.arn
  prompt_lambda_function_invoke_arn = var.prompt_api_lambda_function_invoke_arn
  prompt_lambda_function_arn = var.prompt_api_lambda_function_arn
  prompt_lambda_function_name = var.prompt_api_lambda_function_name
  prompt_lambda_function_alias_name = var.prompt_api_lambda_function_alias_name
}

module "apigateway_ws" {
  source = "./ws"
  chat_ws_lambda_function_invoke_arn = var.chat_ws_lambda_function_invoke_arn
  chat_ws_lambda_function_name = var.chat_ws_lambda_function_name
  chat_ws_lambda_function_alias_name = var.chat_ws_lambda_function_alias_name
  role_arn = aws_iam_role.apigateway_role.arn
}
