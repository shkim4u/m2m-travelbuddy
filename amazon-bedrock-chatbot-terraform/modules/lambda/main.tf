module "lambda_chat_api" {
  source = "./chat-api"
  s3_bucket_name = var.s3_bucket_name
  s3_prefix = "docs"
  call_log_table_name = var.call_log_table_name
  call_log_index_name = var.call_log_index_name
}

module "lambda_chat_ws" {
  source = "./chat-ws"
  s3_bucket_name = var.s3_bucket_name
  s3_prefix = "docs"
  call_log_table_name = var.call_log_table_name
  wss_connection_url = var.wss_connection_url
  https_connection_url = var.https_connection_url
}

module "lambda_upload" {
  source = "./upload"
  s3_bucket_name = var.s3_bucket_name
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
