resource "aws_cloudwatch_log_group" "api_gateway_access_log" {
  name              = "makan-go/prod/api-gateway-access"
  retention_in_days = 7
}
