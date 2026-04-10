resource "aws_cognito_user_pool_client" "android_client" {
  name                                          = local.cognito_user_pool_android_client_name
  user_pool_id                                  = aws_cognito_user_pool.instance.id
  generate_secret                               = null
  refresh_token_validity                        = 30
  auth_session_validity                         = 3
  enable_token_revocation                       = true
  allowed_oauth_flows                           = ["code"]
  allowed_oauth_flows_user_pool_client          = true
  allowed_oauth_scopes                          = ["email", "openid", "phone", "profile"]
  callback_urls                                 = var.android_urls.callback_urls
  enable_propagate_additional_user_context_data = false
  explicit_auth_flows                           = ["ALLOW_ADMIN_USER_PASSWORD_AUTH", "ALLOW_REFRESH_TOKEN_AUTH", "ALLOW_USER_PASSWORD_AUTH", "ALLOW_USER_SRP_AUTH"]
  logout_urls                                   = var.android_urls.logout_urls
  region                                        = var.aws_region
  supported_identity_providers                  = ["COGNITO"]
}

resource "aws_cognito_user_pool_client" "admin_web_client" {
  access_token_validity                         = 60
  allowed_oauth_flows                           = ["code"]
  allowed_oauth_flows_user_pool_client          = true
  allowed_oauth_scopes                          = ["email", "openid", "phone", "profile"]
  auth_session_validity                         = 3
  callback_urls                                 = var.admin_web_urls.callback_urls
  enable_propagate_additional_user_context_data = false
  enable_token_revocation                       = true
  explicit_auth_flows                           = ["ALLOW_REFRESH_TOKEN_AUTH", "ALLOW_USER_AUTH", "ALLOW_USER_SRP_AUTH"]
  generate_secret                               = null
  id_token_validity                             = 60
  logout_urls                                   = var.admin_web_urls.logout_urls
  name                                          = local.cognito_user_pool_admin_web_client_name
  prevent_user_existence_errors                 = "ENABLED"
  refresh_token_validity                        = 5
  region                                        = var.aws_region
  supported_identity_providers                  = ["COGNITO"]
  user_pool_id                                  = aws_cognito_user_pool.instance.id
  token_validity_units {
    access_token  = "minutes"
    id_token      = "minutes"
    refresh_token = "days"
  }
}