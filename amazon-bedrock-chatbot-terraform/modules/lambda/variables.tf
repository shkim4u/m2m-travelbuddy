variable "s3_bucket_name" {}
variable "s3_prefix" {}

variable "call_log_table_name" {}
variable "call_log_index_name" {}

variable "wss_connection_url" {}
variable "https_connection_url" {}

variable "bedrock_region" {
  description = "Bedrock Region"
  type = string
  default = "us-east-1"
}

variable "model_id" {
  description = "Model ID"
  type = string
  default = "anthropic.claude-v2:1"
}
