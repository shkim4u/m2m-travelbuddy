locals {
  ecr_reg   = "${data.aws_caller_identity.this.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com"
  ecr_repo  = "amazon-bedrock-chatbot-ws-lambda"
  image_tag = "latest"

  dkr_img_src_path = "${path.module}/lambda-function"
  dkr_img_src_sha256 = sha256(join("", [for f in fileset(".", "${local.dkr_img_src_path}/**") : file(f)]))

  dkr_build_cmd = <<-EOT
        docker build -t ${local.ecr_reg}/${local.ecr_repo}:${local.image_tag} \
            -f ${local.dkr_img_src_path}/Dockerfile ${path.module}/lambda-function

        aws ecr get-login-password --region ${data.aws_region.current.name} | \
            docker login --username AWS --password-stdin ${local.ecr_reg}

        docker push ${local.ecr_reg}/${local.ecr_repo}:${local.image_tag}
    EOT
}

# local-exec for build and push of docker image
# Why the hell Lambda cannot resolve the API gateway's connection URL?
# https://stackoverflow.com/questions/57965745/dnspython-aws-lambda-function-returning-dns-resolver-answer-object-at-0x7fb830c
resource "null_resource" "build_push_dkr_img" {
  triggers = {
    detect_docker_source_changes = var.force_image_rebuild == true ? timestamp() : local.dkr_img_src_sha256
  }

  provisioner "local-exec" {
    command = local.dkr_build_cmd
  }

  depends_on = [aws_ecr_repository.this]
}
