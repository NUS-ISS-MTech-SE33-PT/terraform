module "cloudwatch" {
  source = "../../modules/cloudwatch"

  tags = local.common_tags

  log_group_names = [
    "${local.common_tags.project}/${local.common_tags.environment}/api-gateway-access",
    "${local.common_tags.project}/${local.common_tags.environment}/review-service",
    "${local.common_tags.project}/${local.common_tags.environment}/spot-service",
    "${local.common_tags.project}/${local.common_tags.environment}/spot-submission-service",
  ]
}

moved {
  from = aws_cloudwatch_log_group.this["makan-go/prod/api-gateway-access"]
  to   = module.cloudwatch.aws_cloudwatch_log_group.this["makan-go/prod/api-gateway-access"]
}

moved {
  from = aws_cloudwatch_log_group.this["makan-go/prod/review-service"]
  to   = module.cloudwatch.aws_cloudwatch_log_group.this["makan-go/prod/review-service"]
}

moved {
  from = aws_cloudwatch_log_group.this["makan-go/prod/spot-service"]
  to   = module.cloudwatch.aws_cloudwatch_log_group.this["makan-go/prod/spot-service"]
}

moved {
  from = aws_cloudwatch_log_group.this["makan-go/prod/spot-submission-service"]
  to   = module.cloudwatch.aws_cloudwatch_log_group.this["makan-go/prod/spot-submission-service"]
}
