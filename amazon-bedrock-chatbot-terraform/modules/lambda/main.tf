module "lambda_chat_api" {
  source = "./chat-api"
}

module "lambda_chat_ws" {
  source = "./chat-ws"
  s3_bucket_name = var.s3_bucket_name
  s3_prefix = "docs"
  call_log_table_name = var.call_log_table_name
  connection_url = var.ws_connection_url
}

module "lambda_upload" {
  source = "./upload"
  bucket_name = var.s3_bucket_name
  s3_prefix = "docs"
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
