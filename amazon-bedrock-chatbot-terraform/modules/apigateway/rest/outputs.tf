output "rest_api_id" {
  value = aws_api_gateway_rest_api.this.id
}

output "rest_api_stage_name" {
  value = aws_api_gateway_stage.this.stage_name
}

output "invoke_url" {
  value = aws_api_gateway_deployment.this.invoke_url
}
