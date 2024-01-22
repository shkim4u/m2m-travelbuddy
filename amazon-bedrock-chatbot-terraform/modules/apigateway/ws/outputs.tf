output "ws_api_id" {
  value = aws_apigatewayv2_api.this.id
}

output "ws_api_stage_name" {
  value = aws_apigatewayv2_stage.ws_api_stage.name
}

output "wss_connection_url" {
  description = "The URL of the websocket connection (WSS)"
  value = "${aws_apigatewayv2_api.this.api_endpoint}/${local.stage_name}/"
}

output "https_connection_url" {
  description = "The URL of the websocket connection (HTTPS)"
  value = "https://${aws_apigatewayv2_api.this.id}.execute-api.${data.aws_region.current.name}.amazonaws.com/${local.stage_name}"
}
