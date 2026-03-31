module "kms_policy" {
  source     = "../../modules/iam"
  aws_region = local.aws_region
  role_name  = "github-actions-terraform-prod-role"
  tags       = local.common_tags
}