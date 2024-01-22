output "chatbot_url" {
  value = module.cloudfront.cloudfront_distribution_url
}

output "wss_connection_url" {
  description = "The URL of the websocket connection"
  value = module.apigateway.wss_connection_url
}

output "https_connection_url" {
  description = "The URL of the websocket connection"
  value = module.apigateway.https_connection_url
}

output "rest_api_id" {
  description = "The id of the REST API"
  value = module.apigateway.rest_api_id
}

output "rest_api_stage" {
  description = "The stage of the REST API"
  value = module.apigateway.rest_api_stage
}

output "api_key" {
  description = "The API key of the REST and WebSocket API"
  value = module.apigateway.api_key
}
