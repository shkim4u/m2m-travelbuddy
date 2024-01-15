locals {
  bedrock_region = var.bedrock_region
  model_id = var.model_id
}

module "lambda_chat_ws" {
  source = "terraform-aws-modules/lambda/aws"

  function_name = "amazon-bedrock-chatbot-ws"
  description   = "Amazon Bedrock Chatbot WebSocket API Lambda function"

  create_package = false

  package_type = "Image"
  architectures = ["x86_64"]

  image_uri = format("%v/%v:%v", local.ecr_reg, local.ecr_repo, local.image_tag)

  environment_variables = {
    bedrock_region: local.bedrock_region,
    model_id: local.model_id,
    s3_bucket: var.s3_bucket_name,
    s3_prefix: var.s3_prefix,
    callLogTableName: var.call_log_table_name,
    conversationMode: true,
    connection_url: var.connection_url
  }

  depends_on = [null_resource.build_push_dkr_img]
}
