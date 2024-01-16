output "wss_connection_url" {
  description = "The URL of the websocket connection"
  value = module.apigateway_ws.wss_connection_url
}

output "https_connection_url" {
  description = "The URL of the websocket connection"
  value = module.apigateway_ws.https_connection_url
}
