variable "bedrock_region"  {
  type    = string
  default = "us-east-1"
}

variable "model_id" {
  type    = string
  default = "anthropic.claude-v2:1"
}

variable "layers" {
  description = "List of Lambda Layer Version ARNs (maximum of 5) to attach to your Lambda Function."
  type        = list(string)
  default     = null
}
