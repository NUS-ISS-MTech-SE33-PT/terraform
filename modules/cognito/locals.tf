locals {
  cognito_user_pool_android_client_name   = "${var.tags.project}-${var.tags.environment}-android-client"
  cognito_user_pool_admin_web_client_name = "${var.tags.project}-${var.tags.environment}-admin-web-client"
}