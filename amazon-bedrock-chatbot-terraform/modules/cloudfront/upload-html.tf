locals {
  html_path = "${path.module}/html"
#  html_path_sha256 = sha256(join("", [for f in fileset(".", "${local.html_path}/**") : file(f)]))
  html_path_sha256 = sha256(join("", [for f in fileset(".", "${local.html_path}/**") : filebase64(f)]))

  upload_html_cmd = <<-EOT
      # sed is not compatible between MacOS and Linust: Linux uses -i, MacOS uses -i ''
      #sed -i 's/WSS_ENDPOINT/${var.wss_connection_url}/g' ${path.module}/html/chat.js
      # Cat all the contents and replace the string in one go
      cat ${path.module}/html/chat-template.js | sed 's,WSS_ENDPOINT,${var.wss_connection_url},g' | sed 's,YOUR_API_KEY_HERE,${var.api_key},g' > ${path.module}/html/chat.js
      cat ${path.module}/html/chat.js | grep "wss:"
      aws s3 sync ${path.module}/html s3://${aws_s3_bucket.this.bucket}
    EOT
}

# CloudFront distribution data.
#data "aws_cloudfront_distribution" "current" {
#  id = aws_cloudfront_distribution.this.id
#}

# local-exec for build and push of docker image
resource "null_resource" "upload_html_cmd" {
  triggers = {
    detect_html_changes = var.force_upload_html == true ? timestamp() : local.html_path_sha256
  }

  provisioner "local-exec" {
    command = local.upload_html_cmd
  }

#  depends_on = [aws_cloudfront_distribution.this]
  depends_on = [aws_s3_bucket.this]
}
