locals {
  admin_web_bucket_name = "makan-go-admin-web"
}

module "s3_admin_web" {
  source = "../../modules/s3_private"

  bucket_name                 = local.admin_web_bucket_name
  cloudfront_distribution_arn = module.cloudfront_admin_web.arn
  tags                        = local.common_tags
}
