module "lambda_chat_api" {
  source = "terraform-aws-modules/lambda/aws"

  function_name = "amazon-bedrock-chatbot-api"
  description   = "Amazon Bedrock Chatbot API Lambda function"

  create_package = false

  package_type = "Image"
  architectures = ["x86_64"]

  image_uri = format("%v/%v:%v", local.ecr_reg, local.ecr_repo, local.image_tag)

  depends_on = [null_resource.build_push_dkr_img]
}
