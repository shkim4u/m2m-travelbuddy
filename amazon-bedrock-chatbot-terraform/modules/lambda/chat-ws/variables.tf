variable "force_image_rebuild" {
  type    = bool
  default = false
}

variable "bedrock_region"  {
  type    = string
  default = "us-east-1"
}

variable "model_id" {
  type    = string
  default = "anthropic.claude-v2:1"
}

variable "s3_bucket_name" {}
variable "s3_prefix" {}

variable "call_log_table_name" {}

variable "wss_connection_url" {}
variable "https_connection_url" {}
