resource "aws_dynamodb_table" "chatbot_call_log" {
  name           = local.table_name
  # Capacity mode can be either "PROVISIONED" or "PAY_PER_REQUEST"
  billing_mode   = "PAY_PER_REQUEST"
  # Partition key.
  hash_key       = "user_id"
  # Sort key.
  range_key      = "request_time"

  attribute {
    name = "user_id"
    type = "S"
  }

  attribute {
    name = "request_time"
    type = "S"
  }

  attribute {
    name = "request_id"
    type = "S"
  }

  # Terraform does not support removal policy for DynamoDB at this time.

  global_secondary_index {
    name               = "${local.table_name}-gsi"
    hash_key           = "request_id"
    projection_type    = "ALL"
#    projection_type    = "KEYS_ONLY"
  }

  tags = {
    Environment = "dev"
    Name        = local.table_name
  }
}
