output "lambda_function_invoke_arn" {
  value = module.lambda_prompt_api.lambda_function_invoke_arn
}

output "lambda_function_arn" {
  value = module.lambda_prompt_api.lambda_function_arn
}

output "lambda_function_name" {
  value = module.lambda_prompt_api.lambda_function_name
}

output "lambda_function_alias_name" {
  value = module.lambda_prompt_api_alias.lambda_alias_name
}
