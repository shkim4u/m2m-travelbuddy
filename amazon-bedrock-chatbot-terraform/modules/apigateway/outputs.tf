output "wss_connection_url" {
  description = "The URL of the websocket connection"
  value = module.apigateway_ws.wss_connection_url
}

output "https_connection_url" {
  description = "The URL of the websocket connection"
  value = module.apigateway_ws.https_connection_url
}

output "rest_api_id" {
  description = "The id of the REST API"
  value = module.apigateway_rest.rest_api_id
}

output "rest_api_stage" {
  description = "The stage of the REST API"
  value = module.apigateway_rest.rest_api_stage_name
}

output "rest_api_invoke_url" {
  description = "The invoke URL of the REST API"
  value = module.apigateway_rest.invoke_url
}

output "api_key" {
  description = "The API key of the REST and WebSocket API"
  value = aws_api_gateway_api_key.this.value
}
