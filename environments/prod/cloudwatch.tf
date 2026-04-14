locals {
  log_group_names = toset([
    "makan-go/prod/api-gateway-access",
    "makan-go/prod/review-service",
    "makan-go/prod/spot-service",
    "makan-go/prod/spot-submission-service",
  ])
}

resource "aws_cloudwatch_log_group" "this" {
  for_each          = local.log_group_names
  name              = each.key
  retention_in_days = 7
}

moved {
  from = aws_cloudwatch_log_group.api_gateway_access_log
  to   = aws_cloudwatch_log_group.this["makan-go/prod/api-gateway-access"]
}

moved {
  from = aws_cloudwatch_log_group.review_service_log
  to   = aws_cloudwatch_log_group.this["makan-go/prod/review-service"]
}

moved {
  from = aws_cloudwatch_log_group.spot_service_log
  to   = aws_cloudwatch_log_group.this["makan-go/prod/spot-service"]
}

moved {
  from = aws_cloudwatch_log_group.spot_submission_service_log
  to   = aws_cloudwatch_log_group.this["makan-go/prod/spot-submission-service"]
}
