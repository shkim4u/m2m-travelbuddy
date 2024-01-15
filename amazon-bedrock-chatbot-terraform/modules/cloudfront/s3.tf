resource "aws_s3_bucket" "this" {
  bucket = var.bucket_name
  force_destroy = true
}

data "aws_iam_policy_document" "this" {
  statement {
    actions = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.this.arn}/*"]

    principals {
      type = "AWS"
      identifiers = ["arn:aws:iam::cloudfront:user/CloudFront Origin Access Identity ${aws_cloudfront_origin_access_identity.this.id}"]
    }
  }
}

resource "aws_s3_bucket_policy" "this" {
  bucket = aws_s3_bucket.this.id
  policy = data.aws_iam_policy_document.this.json
}
