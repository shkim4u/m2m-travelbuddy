output "triggered_by" {
  value = null_resource.build_push_dkr_img.triggers
}

output "lambda_function_invoke_arn" {
  value = module.lambda_simple_ws.lambda_function_invoke_arn
}

output "lambda_function_name" {
  value = module.lambda_simple_ws.lambda_function_name
}
