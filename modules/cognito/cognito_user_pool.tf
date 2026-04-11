resource "aws_cognito_user_pool" "instance" {
  name                     = "${var.tags.project}-${var.tags.environment}-user-pool"
  alias_attributes         = ["email"]
  auto_verified_attributes = ["email"]
  deletion_protection      = "ACTIVE"
  mfa_configuration        = "OFF"
  region                   = var.aws_region
  tags                     = var.tags
  user_pool_tier           = "ESSENTIALS"
  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
    recovery_mechanism {
      name     = "verified_phone_number"
      priority = 2
    }
  }
  admin_create_user_config {
    allow_admin_create_user_only = false
  }
  email_configuration {
    email_sending_account = "COGNITO_DEFAULT"
  }
  password_policy {
    minimum_length                   = 6
    password_history_size            = 0
    require_lowercase                = false
    require_numbers                  = false
    require_symbols                  = false
    require_uppercase                = false
    temporary_password_validity_days = 7
  }
  sign_in_policy {
    allowed_first_auth_factors = ["PASSWORD"]
  }
  verification_message_template {
    default_email_option = "CONFIRM_WITH_CODE"
  }
}
