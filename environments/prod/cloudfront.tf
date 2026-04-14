module "cloudfront_web_static" {
  source = "../../modules/cloudfront_s3"

  oac_name        = "oac-makan-go-web-static.s3.ap-southeast-1.amazonaws.-mkv98v7njbf"
  oac_description = "Created by CloudFront"
  s3_domain_name  = "makan-go-web-static.s3.ap-southeast-1.amazonaws.com"
  origin_id       = "makan-go-web-static.s3.ap-southeast-1.amazonaws.com-mkv97bia8wh"

  default_root_object = "index.html"
  is_ipv6_enabled     = true
  price_class         = "PriceClass_All"
  web_acl_id          = aws_wafv2_web_acl.web_static.arn

  custom_error_responses = [
    { error_code = 403, response_code = 200, response_page_path = "/index.html", error_caching_min_ttl = 10 },
    { error_code = 404, response_code = 200, response_page_path = "/index.html", error_caching_min_ttl = 10 },
  ]

  tags = merge(local.common_tags, { Name = "makan-go-web-static" })
}

module "cloudfront_admin_web" {
  source = "../../modules/cloudfront_s3"

  oac_name        = "makan-go-admin-web-oac"
  oac_description = "Access control for makan-go-admin-web"
  s3_domain_name  = "makan-go-admin-web.s3.ap-southeast-1.amazonaws.com"
  origin_id       = "admin-web-prod"

  comment             = "Public distribution for makan-go-admin-web"
  default_root_object = "index.html"
  hsts_policy_name    = "makan-go-admin-web-security-headers"

  custom_error_responses = [
    { error_code = 403, response_code = 200, response_page_path = "/index.html", error_caching_min_ttl = 0 },
    { error_code = 404, response_code = 200, response_page_path = "/index.html", error_caching_min_ttl = 0 },
  ]

  tags = local.common_tags
}

module "cloudfront_spot_submission" {
  source = "../../modules/cloudfront_s3"

  oac_name        = "makan-go-spot-submissions-oac"
  oac_description = "Access control for makan-go-spot-submissions"
  s3_domain_name  = "makan-go-spot-submissions.s3.ap-southeast-1.amazonaws.com"
  origin_id       = "spot-submission-photos-prod"

  comment          = "Public distribution for makan-go-spot-submissions"
  hsts_policy_name = "makan-go-spot-submissions-security-headers"

  tags = local.common_tags
}
