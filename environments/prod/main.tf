module "kms_policy" {
  source     = "../../modules/iam"
  aws_region = local.aws_region
  role_name  = "terraform-prod-role"
  tags       = locals.common_tags
}