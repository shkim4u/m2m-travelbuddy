data "aws_cloudfront_cache_policy" "CachingDisabled" {
  name = "Managed-CachingDisabled"
}

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

  #>>
  #>> Behavior for Chat REST API.
  #>>
  ordered_cache_behavior {
    path_pattern     = "/chat"
    allowed_methods  = ["GET", "HEAD", "POST", "PUT", "PATCH", "OPTIONS", "DELETE"]
    cached_methods   = ["GET", "HEAD"]
    cache_policy_id = data.aws_cloudfront_cache_policy.CachingDisabled.id
    compress = true
    target_origin_id = "apiGatewayOriginId-chat"

#    forwarded_values {
#      query_string = false
#      headers      = ["*"]
#
#      cookies {
#        forward = "none"
#      }
#    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 0
    max_ttl                = 0
  }

  origin {
    origin_id   = "apiGatewayOriginId-chat"
    domain_name = "${var.rest_api_id}.execute-api.${data.aws_region.current.name}.amazonaws.com"
    origin_path = "/${var.rest_api_stage}"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }
  #<<
  #<< End of behavior for Chat REST API.
  #<<

  #>>
  #>> Behavior for upload REST API.
  #>>
  ordered_cache_behavior {
    path_pattern     = "/upload"
    allowed_methods  = ["GET", "HEAD", "POST", "PUT", "PATCH", "OPTIONS", "DELETE"]
    cached_methods   = ["GET", "HEAD"]
    cache_policy_id = data.aws_cloudfront_cache_policy.CachingDisabled.id
    compress = true
    target_origin_id = "apiGatewayOriginId-upload"

#    forwarded_values {
#      query_string = false
#      headers      = ["*"]
#
#      cookies {
#        forward = "none"
#      }
#    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 0
    max_ttl                = 0
  }

  origin {
    origin_id   = "apiGatewayOriginId-upload"
    domain_name = "${var.rest_api_id}.execute-api.${data.aws_region.current.name}.amazonaws.com"
    origin_path = "/${var.rest_api_stage}"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }
  #<<
  #<< End of behavior for Upload REST API.
  #<<

  #>>
  #>> Behavior for query result REST API.
  #>>
  ordered_cache_behavior {
    path_pattern     = "/query"
    allowed_methods  = ["GET", "HEAD", "POST", "PUT", "PATCH", "OPTIONS", "DELETE"]
    cached_methods   = ["GET", "HEAD"]
    cache_policy_id = data.aws_cloudfront_cache_policy.CachingDisabled.id
    compress = true
    target_origin_id = "apiGatewayOriginId-query-result"

#    forwarded_values {
#      query_string = false
#      headers      = ["*"]
#
#      cookies {
#        forward = "none"
#      }
#    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 0
    max_ttl                = 0
  }

  origin {
    origin_id   = "apiGatewayOriginId-query-result"
    domain_name = "${var.rest_api_id}.execute-api.${data.aws_region.current.name}.amazonaws.com"
    origin_path = "/${var.rest_api_stage}"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }
  #<<
  #<< End of behavior for query result REST API.
  #<<

  #>>
  #>> Behavior for history REST API.
  #>>
  ordered_cache_behavior {
    path_pattern     = "/history"
    allowed_methods  = ["GET", "HEAD", "POST", "PUT", "PATCH", "OPTIONS", "DELETE"]
    cached_methods   = ["GET", "HEAD"]
    cache_policy_id = data.aws_cloudfront_cache_policy.CachingDisabled.id
    compress = true
    target_origin_id = "apiGatewayOriginId-history"

#    forwarded_values {
#      query_string = false
#      headers      = ["*"]
#
#      cookies {
#        forward = "none"
#      }
#    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 0
    max_ttl                = 0
  }

  origin {
    origin_id   = "apiGatewayOriginId-history"
    domain_name = "${var.rest_api_id}.execute-api.${data.aws_region.current.name}.amazonaws.com"
    origin_path = "/${var.rest_api_stage}"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }
  #<<
  #<< End of behavior for history REST API.
  #<<

  #>>
  #>> Behavior for delete log REST API.
  #>>
  ordered_cache_behavior {
    path_pattern     = "/delete"
    allowed_methods  = ["GET", "HEAD", "POST", "PUT", "PATCH", "OPTIONS", "DELETE"]
    cached_methods   = ["GET", "HEAD"]
    cache_policy_id = data.aws_cloudfront_cache_policy.CachingDisabled.id
    compress = true
    target_origin_id = "apiGatewayOriginId-delete-log"

#    forwarded_values {
#      query_string = false
#      headers      = ["*"]
#
#      cookies {
#        forward = "none"
#      }
#    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 0
    max_ttl                = 0
  }

  origin {
    origin_id   = "apiGatewayOriginId-delete-log"
    domain_name = "${var.rest_api_id}.execute-api.${data.aws_region.current.name}.amazonaws.com"
    origin_path = "/${var.rest_api_stage}"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }
  #<<
  #<< End of behavior for delete log REST API.
  #<<

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

# AWS CloudFront behavior for REST APi.
