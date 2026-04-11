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

resource "aws_cloudfront_distribution" "admin_web" {
  comment             = "Public distribution for makan-go-admin-web"
  default_root_object = "index.html"
  enabled             = true
  http_version        = "http2"
  is_ipv6_enabled     = false
  price_class         = "PriceClass_200"
  tags                = local.common_tags

  custom_error_response {
    error_caching_min_ttl = 0
    error_code            = 403
    response_code         = 200
    response_page_path    = "/index.html"
  }

  custom_error_response {
    error_caching_min_ttl = 0
    error_code            = 404
    response_code         = 200
    response_page_path    = "/index.html"
  }

  default_cache_behavior {
    allowed_methods            = ["GET", "HEAD"]
    cache_policy_id            = "658327ea-f89d-4fab-a63d-7e88639e58f6"
    cached_methods             = ["GET", "HEAD"]
    compress                   = true
    default_ttl                = 0
    max_ttl                    = 0
    min_ttl                    = 0
    response_headers_policy_id = "fe32e02f-6a1c-41ca-8a99-0374ecbb8169"
    smooth_streaming           = false
    target_origin_id           = "admin-web-prod"
    viewer_protocol_policy     = "redirect-to-https"
  }

  origin {
    domain_name              = "makan-go-admin-web.s3.ap-southeast-1.amazonaws.com"
    origin_access_control_id = aws_cloudfront_origin_access_control.admin_web.id
    origin_id                = "admin-web-prod"
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

resource "aws_cloudfront_origin_access_control" "web_static" {
  description                       = "Created by CloudFront"
  name                              = "oac-makan-go-web-static.s3.ap-southeast-1.amazonaws.-mkv98v7njbf"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_origin_access_control" "admin_web" {
  description                       = "Access control for makan-go-admin-web"
  name                              = "makan-go-admin-web-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_origin_access_control" "spot_submission" {
  description                       = "Access control for makan-go-spot-submissions"
  name                              = "makan-go-spot-submissions-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}
