output "call_log_table_name" {
  value = aws_dynamodb_table.chatbot_call_log.name
}

output "call_log_index_name" {
  value = [for gsi in aws_dynamodb_table.chatbot_call_log.global_secondary_index : gsi.name if gsi.name == "${local.table_name}-gsi"][0]
}
