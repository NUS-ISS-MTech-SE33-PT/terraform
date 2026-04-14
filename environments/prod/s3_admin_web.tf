locals {
  admin_web_bucket_name = "makan-go-admin-web"
}

module "s3_admin_web" {
  source = "../../modules/s3_private"

  bucket_name                 = local.admin_web_bucket_name
  cloudfront_distribution_arn = module.cloudfront_admin_web.arn
  tags                        = local.common_tags
}

# --- Moved blocks (safe to remove after one successful apply) ---

moved {
  from = aws_s3_bucket.admin_web
  to   = module.s3_admin_web.aws_s3_bucket.this
}

moved {
  from = aws_s3_bucket_ownership_controls.admin_web
  to   = module.s3_admin_web.aws_s3_bucket_ownership_controls.this
}

moved {
  from = aws_s3_bucket_public_access_block.admin_web
  to   = module.s3_admin_web.aws_s3_bucket_public_access_block.this
}

moved {
  from = aws_s3_bucket_server_side_encryption_configuration.admin_web
  to   = module.s3_admin_web.aws_s3_bucket_server_side_encryption_configuration.this
}

moved {
  from = aws_s3_bucket_versioning.admin_web
  to   = module.s3_admin_web.aws_s3_bucket_versioning.this
}

moved {
  from = aws_s3_bucket_policy.admin_web
  to   = module.s3_admin_web.aws_s3_bucket_policy.this
}
