resource "aws_cloudfront_origin_access_control" "web_static" {
  description                       = "Created by CloudFront"
  name                              = "oac-makan-go-web-static.s3.ap-southeast-1.amazonaws.-mkv98v7njbf"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "web_static" {
  default_root_object = "index.html"
  enabled             = true
  http_version        = "http2"
  is_ipv6_enabled     = true
  price_class         = "PriceClass_All"
  tags = merge(local.common_tags, {
    Name = "makan-go-web-static"
  })
  web_acl_id = aws_wafv2_web_acl.web_static.arn

  custom_error_response {
    error_caching_min_ttl = 10
    error_code            = 403
    response_code         = 200
    response_page_path    = "/index.html"
  }

  custom_error_response {
    error_caching_min_ttl = 10
    error_code            = 404
    response_code         = 200
    response_page_path    = "/index.html"
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cache_policy_id        = "658327ea-f89d-4fab-a63d-7e88639e58f6"
    cached_methods         = ["GET", "HEAD"]
    compress               = true
    default_ttl            = 0
    max_ttl                = 0
    min_ttl                = 0
    smooth_streaming       = false
    target_origin_id       = "makan-go-web-static.s3.ap-southeast-1.amazonaws.com-mkv97bia8wh"
    viewer_protocol_policy = "redirect-to-https"
  }

  origin {
    domain_name              = "makan-go-web-static.s3.ap-southeast-1.amazonaws.com"
    origin_access_control_id = aws_cloudfront_origin_access_control.web_static.id
    origin_id                = "makan-go-web-static.s3.ap-southeast-1.amazonaws.com-mkv97bia8wh"
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
