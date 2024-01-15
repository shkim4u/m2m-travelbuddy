resource "aws_apigatewayv2_api" "this" {
  name                       = "amazon-bedrock-chatbot-ws-api"
  protocol_type              = "WEBSOCKET"
  route_selection_expression = "$request.body.action"
  api_key_selection_expression = "$request.header.x-api-key"
  description                = "Amazon Bedrock Chatbot WebSocket API for AWS API Gateway"
}

#resource "aws_apigatewayv2_deployment" "this" {
#  api_id      = aws_apigatewayv2_api.this.id
#  stage_name  = local.stage_name
#  description = local.stage_description
#  lifecycle {
#    create_before_destroy = true
#  }
#}

resource "aws_apigatewayv2_integration" "ws_api_integration" {
  api_id                    = aws_apigatewayv2_api.this.id
  description = "Integration for connect"
  integration_type          = "AWS_PROXY"
  integration_uri           = var.chat_ws_lambda_function_invoke_arn
#  integration_uri           = "arn:aws:apigateway:${data.aws_region.current.name}:lambda:path/2015-03-31/functions/${var.chat_ws_lambda_function_invoke_arn}/invocations"
  credentials_arn           = var.role_arn
  connection_type = "INTERNET"

#  content_handling_strategy = "CONVERT_TO_TEXT"
#  passthrough_behavior      = "WHEN_NO_MATCH"
}

resource "aws_apigatewayv2_route" "connect" {
  api_id    = aws_apigatewayv2_api.this.id
  route_key = "$connect"
  api_key_required = false
  authorization_type = "NONE"
  operation_name = "connect"
  target    = "integrations/${aws_apigatewayv2_integration.ws_api_integration.id}"
}

resource "aws_apigatewayv2_route" "disconnect" {
  api_id    = aws_apigatewayv2_api.this.id
  route_key = "$disconnect"
  api_key_required = false
  authorization_type = "NONE"
  operation_name = "disconnect"
  target    = "integrations/${aws_apigatewayv2_integration.ws_api_integration.id}"
}

resource "aws_apigatewayv2_route" "default" {
  api_id    = aws_apigatewayv2_api.this.id
  route_key = "$default"
  api_key_required = false
  authorization_type = "NONE"
  operation_name = "default"
  target    = "integrations/${aws_apigatewayv2_integration.ws_api_integration.id}"
}

resource "aws_apigatewayv2_deployment" "ws_api_deployment" {
  api_id      = aws_apigatewayv2_api.this.id
  description = "Deployment"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_apigatewayv2_stage" "ws_api_stage" {
  api_id = aws_apigatewayv2_api.this.id
  name   = "dev"
#  deployment_id = aws_apigatewayv2_deployment.ws_api_deployment.id
  auto_deploy   = true
}
