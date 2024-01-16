resource "aws_cloudfront_origin_access_identity" "this" {
  comment = "Amazon Bedrock Chatbot Frontend OAI"
}

resource "aws_cloudfront_distribution" "this" {
  comment = "CloudFront distribution for Amazon Bedrock Chatbot Frontend"
  default_root_object = "index.html"
  enabled = true
  http_version = "http2"

  origin {
    origin_id = aws_s3_bucket.this.id
    domain_name = aws_s3_bucket.this.bucket_regional_domain_name
    s3_origin_config {
      # Restricting bucket access through an origin access identity (OAI).
      origin_access_identity = aws_cloudfront_origin_access_identity.this.cloudfront_access_identity_path
    }
  }

  # Connect the CDN to the origin.
  default_cache_behavior {
    # Compress resources automatically (gzip).
    compress = true
    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    cached_methods = ["GET", "HEAD", "OPTIONS"]
    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
    target_origin_id = aws_s3_bucket.this.id

    viewer_protocol_policy = "allow-all"
  }

  price_class = "PriceClass_All"

  # 지리적 제한: 특정 국가에서만 접근하도록 화이트리스트 작성
  restrictions {
    geo_restriction {
      restriction_type = "none"
      # locations        = ["US", "CA", "GB", "DE"]
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

#resource "aws_s3_bucket_object" "object" {
#  for_each = fileset("${path.module}/your-directory", "*") # replace 'your-directory' with your directory name
#
#  bucket       = aws_s3_bucket.bucket.bucket
#  key          = each.value
#  source       = "${path.module}/your-directory/${each.value}" # replace 'your-directory' with your directory name
#  acl          = "private"
#}
