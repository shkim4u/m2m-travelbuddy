output "triggered_by" {
  value = null_resource.build_push_dkr_img.triggers
}

output "lambda_function_invoke_arn" {
  value = module.lambda_chat_api.lambda_function_invoke_arn
#  value = "${module.lambda_chat_api.lambda_function_invoke_arn}:${module.lambda_chat_api_alias.lambda_alias_name}"
}

output "lambda_function_name" {
  value = module.lambda_chat_api.lambda_function_name
}
