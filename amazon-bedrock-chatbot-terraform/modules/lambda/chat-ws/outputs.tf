output "triggered_by" {
  value = null_resource.build_push_dkr_img.triggers
}

output "lambda_function_invoke_arn" {
  value = module.lambda_chat_ws.lambda_function_invoke_arn
}

output "lambda_function_name" {
  value = module.lambda_chat_ws.lambda_function_name
}

output "bedrock_region"  {
  value = var.bedrock_region
}

output "model_id" {
  value = var.model_id
}
