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
