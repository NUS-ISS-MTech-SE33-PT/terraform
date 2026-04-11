output "user_pool_id" {
  value = aws_cognito_user_pool.instance.id
}

output "android_client_id" {
  value = aws_cognito_user_pool_client.android_client.id
}

output "admin_web_client_id" {
  value = aws_cognito_user_pool_client.admin_web_client.id
}
