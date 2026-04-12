resource "aws_cloudfront_origin_access_control" "spot_submission" {
  description                       = "Access control for makan-go-spot-submissions"
  name                              = "makan-go-spot-submissions-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "spot_submission" {
  comment         = "Public distribution for makan-go-spot-submissions"
  enabled         = true
  http_version    = "http2"
  is_ipv6_enabled = false
  price_class     = "PriceClass_200"
  tags            = local.common_tags

  default_cache_behavior {
    allowed_methods            = ["GET", "HEAD"]
    cache_policy_id            = "658327ea-f89d-4fab-a63d-7e88639e58f6"
    cached_methods             = ["GET", "HEAD"]
    compress                   = true
    default_ttl                = 0
    max_ttl                    = 0
    min_ttl                    = 0
    response_headers_policy_id = "7770778d-6ad9-4e76-a38d-2e11565e9436"
    smooth_streaming           = false
    target_origin_id           = "spot-submission-photos-prod"
    viewer_protocol_policy     = "redirect-to-https"
  }

  origin {
    domain_name              = "makan-go-spot-submissions.s3.ap-southeast-1.amazonaws.com"
    origin_access_control_id = aws_cloudfront_origin_access_control.spot_submission.id
    origin_id                = "spot-submission-photos-prod"
  }

  restrictions {
    geo_restriction {
      locations        = []
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}
