resource "aws_apigatewayv2_api" "this" {
  name                       = "amazon-bedrock-chatbot-ws-api"
  protocol_type              = "WEBSOCKET"
  route_selection_expression = "$request.body.action"
  api_key_selection_expression = "$request.header.x-api-key"
  description                = "Amazon Bedrock Chatbot WebSocket API for AWS API Gateway"
}

resource "aws_apigatewayv2_integration" "ws_api_integration_connect" {
  api_id                    = aws_apigatewayv2_api.this.id
  description = "Integration for connect"
  connection_type = "INTERNET"
  integration_type          = "AWS_PROXY"
#  integration_uri           = var.chat_ws_lambda_function_invoke_arn
  integration_uri           = "arn:aws:apigateway:${data.aws_region.current.name}:lambda:path/2015-03-31/functions/arn:aws:lambda:${data.aws_region.current.name}:${data.aws_caller_identity.this.account_id}:function:${var.chat_ws_lambda_function_name}:${var.chat_ws_lambda_function_alias_name}/invocations"
  integration_method = "POST"
  credentials_arn           = var.role_arn
  passthrough_behavior      = "WHEN_NO_MATCH"
  timeout_milliseconds = 29000
  content_handling_strategy = "CONVERT_TO_TEXT"
  payload_format_version = "1.0"
}

resource "aws_apigatewayv2_integration" "ws_api_integration_default" {
  api_id                    = aws_apigatewayv2_api.this.id
  description = "Integration for default"
  connection_type = "INTERNET"
  integration_type          = "AWS_PROXY"
#  integration_uri           = var.chat_ws_lambda_function_invoke_arn
  integration_uri           = "arn:aws:apigateway:${data.aws_region.current.name}:lambda:path/2015-03-31/functions/arn:aws:lambda:${data.aws_region.current.name}:${data.aws_caller_identity.this.account_id}:function:${var.chat_ws_lambda_function_name}:${var.chat_ws_lambda_function_alias_name}/invocations"
  integration_method = "POST"
  credentials_arn           = var.role_arn
  passthrough_behavior      = "WHEN_NO_MATCH"
  timeout_milliseconds = 29000
  content_handling_strategy = "CONVERT_TO_TEXT"
  payload_format_version = "1.0"
}

resource "aws_apigatewayv2_integration" "ws_api_integration_disconnect" {
  api_id                    = aws_apigatewayv2_api.this.id
  description = "Integration for disconnect"
  connection_type = "INTERNET"
  integration_type          = "AWS_PROXY"
#  integration_uri           = var.chat_ws_lambda_function_invoke_arn
  integration_uri           = "arn:aws:apigateway:${data.aws_region.current.name}:lambda:path/2015-03-31/functions/arn:aws:lambda:${data.aws_region.current.name}:${data.aws_caller_identity.this.account_id}:function:${var.chat_ws_lambda_function_name}:${var.chat_ws_lambda_function_alias_name}/invocations"
  integration_method = "POST"
  credentials_arn           = var.role_arn
  passthrough_behavior      = "WHEN_NO_MATCH"
  timeout_milliseconds = 29000
  content_handling_strategy = "CONVERT_TO_TEXT"
  payload_format_version = "1.0"
}

resource "aws_apigatewayv2_route" "connect" {
  api_id    = aws_apigatewayv2_api.this.id
  route_key = "$connect"
  api_key_required = false
  authorization_type = "NONE"
#  operation_name = "connect"
  target    = "integrations/${aws_apigatewayv2_integration.ws_api_integration_connect.id}"
}

resource "aws_apigatewayv2_route" "disconnect" {
  api_id    = aws_apigatewayv2_api.this.id
  route_key = "$disconnect"
  api_key_required = false
  authorization_type = "NONE"
#  operation_name = "disconnect"
  target    = "integrations/${aws_apigatewayv2_integration.ws_api_integration_disconnect.id}"
}

resource "aws_apigatewayv2_route" "default" {
  api_id    = aws_apigatewayv2_api.this.id
  route_key = "$default"
  api_key_required = false
  authorization_type = "NONE"
#  operation_name = "default"
  target    = "integrations/${aws_apigatewayv2_integration.ws_api_integration_default.id}"
}

resource "aws_apigatewayv2_deployment" "ws_api_deployment" {
  api_id      = aws_apigatewayv2_api.this.id
  description = "Deployment"

  lifecycle {
    create_before_destroy = true
  }

  # Manually trigger redeployment https://www.terraform.io/cli/commands/taint
  #   '$ terraform taint modules.apigateway.ws.aws_apigatewayv2_deployment.wsapi_deploy'
  triggers = {
#    redeployment = sha1(jsonencode(aws_apigatewayv2_api.this.body))
    redeployment = sha1(join(",", tolist([
      jsonencode(aws_apigatewayv2_api.this.body),
      jsonencode(aws_apigatewayv2_route.connect),
      jsonencode(aws_apigatewayv2_integration.ws_api_integration_connect),
      jsonencode(aws_apigatewayv2_route.default),
      jsonencode(aws_apigatewayv2_integration.ws_api_integration_default),
      jsonencode(aws_apigatewayv2_route.disconnect),
      jsonencode(aws_apigatewayv2_integration.ws_api_integration_disconnect)
    ])))
  }

  depends_on = [aws_apigatewayv2_route.connect,
    aws_apigatewayv2_route.default,
    aws_apigatewayv2_route.disconnect,
    aws_apigatewayv2_integration.ws_api_integration_connect,
    aws_apigatewayv2_integration.ws_api_integration_default,
    aws_apigatewayv2_integration.ws_api_integration_disconnect
  ]
}

resource "aws_apigatewayv2_stage" "ws_api_stage" {
  api_id = aws_apigatewayv2_api.this.id
  name   = "dev"
  deployment_id = aws_apigatewayv2_deployment.ws_api_deployment.id
#  auto_deploy   = true

  default_route_settings {
    data_trace_enabled = true
    logging_level = "INFO"
    throttling_burst_limit = 50
    throttling_rate_limit = 100

    #    custom_access_log_settings {
#      format = jsonencode({
#        requestId               = "$context.requestId"
#        requestTime             = "$context.requestTime"
#        httpMethod              = "$context.httpMethod"
#        path                    = "$context.path"
#        routeKey                = "$context.routeKey"
#        status                  = "$context.status"
#        protocol                = "$context.protocol"
#        responseLength          = "$context.responseLength"
#        integrationLatency      = "$context.integrationLatency"
#        integrationStatus       = "$context.integrationStatus"
#        integrationErrorMessage = "$context.integrationErrorMessage"
#        integrationErrorCode    = "$context.integrationErrorCode"
#        integrationResponseCode = "$context.integrationResponseCode"
#        integrationProtocol     = "$context.integrationProtocol"
#        integrationDataTrace    = "$context.integrationDataTrace"
#        apiId                   = "$context.apiId"
#        connectedAt             = "$context.connectedAt"
#        connectionId            = "$context.connectionId"
#        domainName              = "$context.domainName"
#        domainPrefix            = "$context.domainPrefix"
#        error                   = "$context.error"
#        eventType               = "$context.eventType"
#        extendedRequestId       = "$context.extendedRequestId"
#        messageDirection        = "$context.messageDirection"
#        messagePayload          = "$context.messagePayload"
#        messageRouteKey         = "$context.messageRouteKey"
#        messageId               = "$context.messageId"
#        requestTimeEpoch        = "$context.requestTimeEpoch"
#        routeKey                = "$context.routeKey"
#        stage                   = "$context.stage"
#        status                  = "$context.status"
#        requestId               = "$context.requestId"
#        requestTime             = "$context.requestTime"
#        routeKey                = "$context.routeKey"
#        stage                   = "$context.stage"
#        status                  = "$context.status"
#        requestId               = "$context.requestId"
#        requestTime             = "$context.requestTime"
#        routeKey                = "$context.routeKey"
#        stage                   = "$context.stage"
#        status                  = "$context.status"
#        requestId               = "$context.requestId"
#        requestTime             = "$context.requestTime"
#        routeKey                = "$context.routeKey"
#        stage                   = "$context.stage"
#        status                  = "$context.status"
#        requestId               = "$context.requestId"
#        requestTime             = "$context.requestTime"
#        routeKey                = "$context.routeKey"
#        stage                   = "$context.stage"
#        status                  = "$context.status"
#        requestId               = "$context.requestId"
#        requestTime             = "$context.requestTime"
#        routeKey                = "$context.routeKey"
#        stage                   = "$context.stage"
#        status                  = "$context.status"
#        requestId               = "$context.requestId"
#      })
#    }
  }
}

resource "aws_lambda_permission" "allow_api_gateway_any" {
  statement_id  = "AllowExecutionFromSpecificAPIGateway"
  action        = "lambda:InvokeFunction"
#  function_name = var.chat_ws_lambda_function_name
  function_name = "${var.chat_ws_lambda_function_name}:${var.chat_ws_lambda_function_alias_name}"
  principal     = "apigateway.amazonaws.com"
#  source_arn    = "arn:aws:execute-api:${data.aws_region.current.name}:${data.aws_caller_identity.this.account_id}:${aws_apigatewayv2_api.this.id}/*/${aws_apigatewayv2_route.connect.route_key}"
#  source_arn    = "${aws_apigatewayv2_stage.ws_api_stage.execution_arn}/*/*/*"
  source_arn    = "${aws_apigatewayv2_api.this.execution_arn}/*/*"
}

resource "aws_lambda_permission" "allow_api_gateway_connect" {
  statement_id  = "AllowExecutionFromSpecificAPIGateway-connect"
  action        = "lambda:InvokeFunction"
#  function_name = var.chat_ws_lambda_function_name
  function_name = "${var.chat_ws_lambda_function_name}:${var.chat_ws_lambda_function_alias_name}"
  principal     = "apigateway.amazonaws.com"
#  source_arn    = "arn:aws:execute-api:${data.aws_region.current.name}:${data.aws_caller_identity.this.account_id}:${aws_apigatewayv2_api.this.id}/*/${aws_apigatewayv2_route.connect.route_key}"
  source_arn    = "${aws_apigatewayv2_api.this.execution_arn}/*/$connect"
}

resource "aws_lambda_permission" "allow_api_gateway_default" {
  statement_id  = "AllowExecutionFromSpecificAPIGateway-default"
  action        = "lambda:InvokeFunction"
#  function_name = var.chat_ws_lambda_function_name
  function_name = "${var.chat_ws_lambda_function_name}:${var.chat_ws_lambda_function_alias_name}"
  principal     = "apigateway.amazonaws.com"
#  source_arn    = "arn:aws:execute-api:${data.aws_region.current.name}:${data.aws_caller_identity.this.account_id}:${aws_apigatewayv2_api.this.id}/*/${aws_apigatewayv2_route.default.route_key}"
  source_arn    = "${aws_apigatewayv2_api.this.execution_arn}/*/$default"
}

resource "aws_lambda_permission" "allow_api_gateway_disconnect" {
  statement_id  = "AllowExecutionFromSpecificAPIGateway-disconnect"
  action        = "lambda:InvokeFunction"
#  function_name = var.chat_ws_lambda_function_name
  function_name = "${var.chat_ws_lambda_function_name}:${var.chat_ws_lambda_function_alias_name}"
  principal     = "apigateway.amazonaws.com"
#  source_arn    = "arn:aws:execute-api:${data.aws_region.current.name}:${data.aws_caller_identity.this.account_id}:${aws_apigatewayv2_api.this.id}/*/${aws_apigatewayv2_route.disconnect.route_key}"
  source_arn    = "${aws_apigatewayv2_api.this.execution_arn}/*/$disconnect"
}
