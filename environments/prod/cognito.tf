locals {
  mobile_auth_url    = "makango://auth"
  web_root_url       = "https://${module.cloudfront_web_static.domain_name}"
  admin_web_root_url = "https://${module.cloudfront_admin_web.domain_name}"
}

module "cognito" {
  source     = "../../modules/cognito"
  aws_region = local.aws_region
  tags       = local.common_tags
  android_urls = {
    callback_urls = [
      "${local.mobile_auth_url}/signin-callback",
      "http://localhost:8080/cb",
      "${local.web_root_url}/auth.html"
    ],
    logout_urls = [
      "${local.mobile_auth_url}/signout",
      "${local.web_root_url}/"
    ]
  }

  admin_web_urls = {
    callback_urls = [
      "http://127.0.0.1:5173/auth/callback",
      "http://localhost:5173/auth/callback",
      "${local.admin_web_root_url}/auth/callback"
    ],
    logout_urls = [
      "http://127.0.0.1:5173/",
      "http://localhost:5173/",
      "${local.admin_web_root_url}/"
    ]
  }
}