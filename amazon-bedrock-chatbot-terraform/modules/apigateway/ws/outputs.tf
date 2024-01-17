output "wss_connection_url" {
  description = "The URL of the websocket connection (WSS)"
  value = "${aws_apigatewayv2_api.this.api_endpoint}/${local.stage_name}/"
}

output "https_connection_url" {
  description = "The URL of the websocket connection (HTTPS)"
  value = "https://${aws_apigatewayv2_api.this.id}.execute-api.${data.aws_region.current.name}.amazon.com/${local.stage_name}"
}
