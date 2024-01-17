output s3_bucket_name {
    value = aws_s3_bucket.this.bucket
}

output cloudfront_distribution_url {
    value = "https://${aws_cloudfront_distribution.this.domain_name}/index.html"
}

