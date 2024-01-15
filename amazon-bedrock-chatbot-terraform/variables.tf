variable "region" {
  description = "AWS Region"
  type = string
  default = "ap-northeast-2"
}

variable "stage" {
  description = "Stage"
  type = string
  default = "dev"
}

variable "s3_prefix" {
  description = "S3 Prefix"
  type = string
  default = "docs"
}

variable "project_name" {
  description = "Project Name"
  type = string
  default = "amazon-bedrock-chatbot"
}

variable "model_id" {
  description = "Model ID"
  type = string
  default = "anthropic.claude-v2:1"
}
