# Terraform AWS resource for API Gateway.
resource "aws_api_gateway_rest_api" "this" {
  name        = "amazon-bedrock-chatbot-rest-api"
  description = "Amazon Bedrock Chatbot REST API for AWS API Gateway"

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  binary_media_types = ["application/pdf", "text/plain", "text/csv"]
}

#>>
#>> Chat API
#>>
resource "aws_api_gateway_resource" "chat" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_rest_api.this.root_resource_id
  path_part   = "chat"
}

resource "aws_api_gateway_method" "chat" {
  rest_api_id   = aws_api_gateway_rest_api.this.id
  resource_id   = aws_api_gateway_resource.chat.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_method_response" "chat" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_resource.chat.id
  http_method = aws_api_gateway_method.chat.http_method
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_integration" "chat" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_resource.chat.id
  http_method = aws_api_gateway_method.chat.http_method

  integration_http_method = "POST"
  type                    = "AWS"
  passthrough_behavior = "WHEN_NO_TEMPLATES"

  uri                     = var.chat_api_lambda_function_invoke_arn

  credentials = var.role_arn
}

resource "aws_api_gateway_integration_response" "chat" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_resource.chat.id
  http_method = aws_api_gateway_method.chat.http_method
  status_code = aws_api_gateway_method_response.chat.status_code
}

#<<
#<< End of Chat API
#<<

#>>
#>> Upload
#>>
resource "aws_api_gateway_resource" "upload" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_rest_api.this.root_resource_id
  path_part   = "upload"
}

resource "aws_api_gateway_method" "upload" {
  rest_api_id   = aws_api_gateway_rest_api.this.id
  resource_id   = aws_api_gateway_resource.upload.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_method_response" "upload" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_resource.upload.id
  http_method = aws_api_gateway_method.upload.http_method
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_integration" "upload" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_resource.upload.id
  http_method = aws_api_gateway_method.upload.http_method

  integration_http_method = "POST"
  type                    = "AWS"
  passthrough_behavior = "WHEN_NO_TEMPLATES"

  uri                     = var.upload_lambda_function_invoke_arn

  credentials = var.role_arn
}

resource "aws_api_gateway_integration_response" "upload" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_resource.upload.id
  http_method = aws_api_gateway_method.upload.http_method
  status_code = aws_api_gateway_method_response.upload.status_code
}

#<<
#<< End of Upload
#<<

#>>
#>> Query Result.
#>>
resource "aws_api_gateway_resource" "query_result" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_rest_api.this.root_resource_id
  path_part   = "query"
}

resource "aws_api_gateway_method" "query_result" {
  rest_api_id   = aws_api_gateway_rest_api.this.id
  resource_id   = aws_api_gateway_resource.query_result.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_method_response" "query_result" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_resource.query_result.id
  http_method = aws_api_gateway_method.query_result.http_method
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_integration" "query_result" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_resource.query_result.id
  http_method = aws_api_gateway_method.query_result.http_method

  integration_http_method = "POST"
  type                    = "AWS"
  passthrough_behavior = "WHEN_NO_TEMPLATES"

  uri                     = var.query_result_lambda_function_invoke_arn

  credentials = var.role_arn
}

resource "aws_api_gateway_integration_response" "query_result" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_resource.query_result.id
  http_method = aws_api_gateway_method.query_result.http_method
  status_code = aws_api_gateway_method_response.query_result.status_code
}
#<<
#<< End of Query Result.
#<<

#>>
#>> History
#>>
resource "aws_api_gateway_resource" "history" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_rest_api.this.root_resource_id
  path_part   = "history"
}

resource "aws_api_gateway_method" "history" {
  rest_api_id   = aws_api_gateway_rest_api.this.id
  resource_id   = aws_api_gateway_resource.history.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_method_response" "history" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_resource.history.id
  http_method = aws_api_gateway_method.history.http_method
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_integration" "history" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_resource.history.id
  http_method = aws_api_gateway_method.history.http_method

  integration_http_method = "POST"
  type                    = "AWS"
  passthrough_behavior = "WHEN_NO_TEMPLATES"

  uri                     = var.history_lambda_function_invoke_arn

  credentials = var.role_arn
}

resource "aws_api_gateway_integration_response" "history" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_resource.history.id
  http_method = aws_api_gateway_method.history.http_method
  status_code = aws_api_gateway_method_response.history.status_code
}
#<<
#<< End of history.
#<<

#>>
#>> Delete log.
#>>
resource "aws_api_gateway_resource" "delete_log" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_rest_api.this.root_resource_id
  path_part   = "delete"
}

resource "aws_api_gateway_method" "delete_log" {
  rest_api_id   = aws_api_gateway_rest_api.this.id
  resource_id   = aws_api_gateway_resource.delete_log.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_method_response" "delete_log" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_resource.delete_log.id
  http_method = aws_api_gateway_method.delete_log.http_method
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_integration" "delete_log" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_resource.delete_log.id
  http_method = aws_api_gateway_method.delete_log.http_method

  integration_http_method = "POST"
  type                    = "AWS"
  passthrough_behavior = "WHEN_NO_TEMPLATES"

  uri                     = var.delete_log_lambda_function_invoke_arn

  credentials = var.role_arn
}

resource "aws_api_gateway_integration_response" "delete_log" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_resource.delete_log.id
  http_method = aws_api_gateway_method.delete_log.http_method
  status_code = aws_api_gateway_method_response.delete_log.status_code
}
#<<
#<< End of delete log.
#<<

resource "aws_api_gateway_deployment" "this" {
  depends_on  = [aws_api_gateway_integration.chat]
  rest_api_id = aws_api_gateway_rest_api.this.id
  stage_name  = local.stage_name
  description = local.stage_description
}

resource "aws_lambda_permission" "allow_api_gateway_chat" {
  statement_id  = "AllowExecutionFromSpecificAPIGateway-chat"
  action        = "lambda:InvokeFunction"
  function_name = var.chat_api_lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_deployment.this.execution_arn}/POST/chat"
}

resource "aws_lambda_permission" "allow_api_gateway_upload" {
  statement_id  = "AllowExecutionFromSpecificAPIGateway-upload"
  action        = "lambda:InvokeFunction"
  function_name = var.upload_lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_deployment.this.execution_arn}/POST/upload"
}

resource "aws_lambda_permission" "allow_api_gateway_query_result" {
  statement_id  = "AllowExecutionFromSpecificAPIGateway-query-result"
  action        = "lambda:InvokeFunction"
  function_name = var.query_result_lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_deployment.this.execution_arn}/POST/query"
}

resource "aws_lambda_permission" "allow_api_gateway_history" {
  statement_id  = "AllowExecutionFromSpecificAPIGateway-history"
  action        = "lambda:InvokeFunction"
  function_name = var.history_lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_deployment.this.execution_arn}/POST/history"
}

resource "aws_lambda_permission" "allow_api_gateway_delete_log" {
  statement_id  = "AllowExecutionFromSpecificAPIGateway-delete-log"
  action        = "lambda:InvokeFunction"
  function_name = var.delete_log_lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_deployment.this.execution_arn}/POST/delete"
}
