resource "aws_cloudfront_response_headers_policy" "hsts" {
  count = var.hsts_policy_name != null ? 1 : 0

  name = var.hsts_policy_name

  security_headers_config {
    strict_transport_security {
      access_control_max_age_sec = 31536000
      include_subdomains         = true
      override                   = true
      preload                    = false
    }
  }
}

resource "aws_cloudfront_origin_access_control" "this" {
  name                              = var.oac_name
  description                       = var.oac_description
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "this" {
  comment             = var.comment
  default_root_object = var.default_root_object
  enabled             = true
  http_version        = "http2"
  is_ipv6_enabled     = var.is_ipv6_enabled
  price_class         = var.price_class
  web_acl_id          = var.web_acl_id
  tags                = var.tags

  origin {
    domain_name              = var.s3_domain_name
    origin_id                = var.origin_id
    origin_access_control_id = aws_cloudfront_origin_access_control.this.id
  }

  default_cache_behavior {
    allowed_methods            = ["GET", "HEAD"]
    cached_methods             = ["GET", "HEAD"]
    target_origin_id           = var.origin_id
    cache_policy_id            = "658327ea-f89d-4fab-a63d-7e88639e58f6"
    response_headers_policy_id = var.hsts_policy_name != null ? aws_cloudfront_response_headers_policy.hsts[0].id : null
    viewer_protocol_policy     = "redirect-to-https"
    compress                   = true
    default_ttl                = 0
    min_ttl                    = 0
    max_ttl                    = 0
    smooth_streaming           = false
  }

  dynamic "custom_error_response" {
    for_each = var.custom_error_responses
    content {
      error_code            = custom_error_response.value.error_code
      response_code         = custom_error_response.value.response_code
      response_page_path    = custom_error_response.value.response_page_path
      error_caching_min_ttl = custom_error_response.value.error_caching_min_ttl
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
      locations        = []
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}
