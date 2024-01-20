output "chat_api_lambda_function_invoke_arn" {
  value = module.lambda_chat_api.lambda_function_invoke_arn
}

output "chat_api_lambda_function_name" {
  value = module.lambda_chat_api.lambda_function_name
}

output "upload_lambda_function_invoke_arn" {
  value = module.lambda_upload.lambda_function_invoke_arn
}

output "upload_lambda_function_name" {
  value = module.lambda_upload.lambda_function_name
}

output "query_result_lambda_function_invoke_arn" {
  value = module.lambda_query_result.lambda_function_invoke_arn
}

output "query_result_lambda_function_name" {
  value = module.lambda_query_result.lambda_function_name
}

output "history_lambda_function_invoke_arn" {
  value = module.lambda_history.lambda_function_invoke_arn
}

output "history_lambda_function_name" {
  value = module.lambda_history.lambda_function_name
}

output "delete_log_lambda_function_invoke_arn" {
  value = module.lambda_delete_log.lambda_function_invoke_arn
}

output "delete_log_lambda_function_name" {
  value = module.lambda_delete_log.lambda_function_name
}

output "chat_ws_lambda_function_invoke_arn" {
  value = module.lambda_chat_ws.lambda_function_invoke_arn
}

output "chat_ws_lambda_function_name" {
  value = module.lambda_chat_ws.lambda_function_name
}

output "bedrock_region" {
  value = module.lambda_chat_ws.bedrock_region
}

output "model_id" {
  value = module.lambda_chat_ws.model_id
}
