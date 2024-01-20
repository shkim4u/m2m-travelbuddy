module "cloudfront" {
  source = "./modules/cloudfront"
  bucket_name = "${var.project_name}-${data.aws_region.current.name}-${data.aws_caller_identity.current.account_id}"
  wss_connection_url = module.apigateway.wss_connection_url
#  wss_connection_url = "<WebSocket URL (wss)>"
  rest_api_id = module.apigateway.rest_api_id
  rest_api_stage = module.apigateway.rest_api_stage
}

module "dynamodb" {
  source = "./modules/dynamodb"
}

module "lambda" {
  source = "./modules/lambda"
  s3_bucket_name = module.cloudfront.s3_bucket_name
  call_log_table_name = module.dynamodb.call_log_table_name
  call_log_index_name = module.dynamodb.call_log_index_name
  wss_connection_url = module.apigateway.wss_connection_url
  https_connection_url = module.apigateway.https_connection_url
  s3_prefix = var.s3_prefix
}

module "apigateway" {
  source = "./modules/apigateway"
  chat_api_lambda_function_invoke_arn = module.lambda.chat_api_lambda_function_invoke_arn
  chat_api_lambda_function_name = module.lambda.chat_api_lambda_function_name
  upload_lambda_function_invoke_arn = module.lambda.upload_lambda_function_invoke_arn
  upload_lambda_function_name = module.lambda.upload_lambda_function_name
  query_result_lambda_function_invoke_arn = module.lambda.query_result_lambda_function_invoke_arn
  query_result_lambda_function_name = module.lambda.query_result_lambda_function_name
  history_lambda_function_invoke_arn = module.lambda.history_lambda_function_invoke_arn
  history_lambda_function_name = module.lambda.history_lambda_function_name
  delete_log_lambda_function_invoke_arn = module.lambda.delete_log_lambda_function_invoke_arn
  delete_log_lambda_function_name = module.lambda.delete_log_lambda_function_name
  # Function ARN for WebSocket API
  chat_ws_lambda_function_invoke_arn = module.lambda.chat_ws_lambda_function_invoke_arn
  chat_ws_lambda_function_name = module.lambda.chat_ws_lambda_function_name
}

#locals {
#  update_function_cmd = <<EOF
#    # Get current config from Lambda.
#    aws lambda update-function-configuration --function-name "${module.lambda.chat_ws_lambda_function_name}" --environment "Variables={connection_url=${module.apigateway.https_connection_url},bedrock_region=${module.lambda.bedrock_region},model_id=${module.lambda.model_id},s3_bucket=${module.cloudfront.s3_bucket_name},s3_prefix=docs,callLogTableName=${module.dynamodb.call_log_table_name},conversationMode=true}" --region ${data.aws_region.current.name}
#
#    #aws lambda update-function-configuration --function-name "${module.lambda.chat_ws_lambda_function_name}" --description redeploy --region ${data.aws_region.current.name}
#  EOF
#}
#
#resource "null_resource" "after_create" {
#  triggers = {
#    hook_after_create = timestamp()
#  }
#
#  provisioner "local-exec" {
#    command = local.update_function_cmd
#  }
#
#  depends_on = [module.apigateway.https_connection_url]
#}
