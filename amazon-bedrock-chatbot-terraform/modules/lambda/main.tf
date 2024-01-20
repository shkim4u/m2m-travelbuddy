module "lambda_chat_api" {
  source = "./chat-api"
  s3_bucket_name = var.s3_bucket_name
  s3_prefix = var.s3_prefix
  call_log_table_name = var.call_log_table_name
  call_log_index_name = var.call_log_index_name
  bedrock_region = var.bedrock_region
  model_id = var.model_id
}

module "lambda_chat_ws" {
  source = "./chat-ws"
  s3_bucket_name = var.s3_bucket_name
  s3_prefix = var.s3_prefix
  call_log_table_name = var.call_log_table_name
  ### (중요) 아래 값을 변경해야 함.
  ### https_connection_url = var.https_connection_url
  # 위와 같이 WebSocket API Gateway의 @connection URL을 사용하여 자동으로 설정하게 하면 Lambda 함수 내부에서 "Name or service not known" 오류가 발생함.
  # (확인 필요) 이 오류는 Lambda 함수가 실행되는 VPC 내부에서는 발생하지 않음.
  # 따라서, 아래와 같이 WebSocket API Gateway의 @connection URL을 직접 입력해야 함.
  # (짐작) 이는 IaC 코드 상에서 발생하는 상호 참조 문제로 보임. (Lambda -> API Gateway: Integration을 위한 Invoke ARN, API Gateway -> @connection URL)
  # Ooooops! Looks like I've tried to with WRONG https_connection_url with domain name ending with ".execute-api.ap-northeast-2.amazon.com", which should be ".execute-api.ap-northeast-2.amazonaws.com".
  https_connection_url = var.https_connection_url
#  https_connection_url = "https://ibq8wmzt70.execute-api.ap-northeast-2.amazonaws.com/dev"
  bedrock_region = var.bedrock_region
  model_id = var.model_id
}

###
### Simple WebSocket Lambda function for testing.
###
module "lambda_simple_ws" {
  source = "./simple-ws"
}

module "lambda_upload" {
  source = "./upload"
  s3_bucket_name = var.s3_bucket_name
  s3_prefix = var.s3_prefix
}

module "lambda_query_result" {
  source = "./query-result"
  call_log_table_name = var.call_log_table_name
  call_log_index_name = var.call_log_index_name
}

module "lambda_history" {
  source = "./history"
  call_log_table_name = var.call_log_table_name
}

module "lambda_delete_log" {
  source = "./delete-log"
  call_log_table_name = var.call_log_table_name
}

#locals {
#  update_function_cmd = <<EOF
#    # Update the Lambda function that is needed.
#    aws lambda update-function-configuration --function-name "${module.lambda_chat_ws.lambda_function_name}" --description "Amazon Bedrock Chatbot WebSocket API Lambda function" --region ${data.aws_region.current.name}
#  EOF
#}
#
#resource "null_resource" "after_create" {
#  triggers = {
#    hook_after_create = timestamp()
#  }
#
#  provisioner "local-exec" {
#    command = local.update_function_cmd
#  }
#
#  depends_on = [module.lambda_chat_ws]
#}
