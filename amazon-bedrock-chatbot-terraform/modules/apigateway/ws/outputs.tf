output "ws_connection_url" {
  description = "The URL of the websocket connection"
  value = "${aws_apigatewayv2_api.this.api_endpoint}/${local.stage_name}"
}
