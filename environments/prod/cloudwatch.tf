resource "aws_cloudwatch_log_group" "api_gateway_access_log" {
  name              = "makan-go/prod/api-gateway-access"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "review_service_log" {
  name              = "makan-go/prod/review-service"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "spot_service_log" {
  name              = "makan-go/prod/spot-service"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "spot_submission_service_log" {
  name              = "makan-go/prod/spot-submission-service"
  retention_in_days = 7
}
