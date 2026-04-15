locals {
  spot_submission_bucket_name = "makan-go-spot-submissions"
}

module "s3_spot_submission_photos" {
  source = "../../modules/s3_private"

  bucket_name                 = local.spot_submission_bucket_name
  cloudfront_distribution_arn = module.cloudfront_spot_submission.arn
  tags                        = local.common_tags

  lifecycle_rules = [
    {
      id              = "expire-old-uploads"
      prefix          = "submissions/"
      expiration_days = 365
    },
  ]

  cors_rules = [
    {
      allowed_headers = ["*"]
      allowed_methods = ["GET", "HEAD", "POST", "PUT"]
      allowed_origins = ["*"]
      expose_headers  = []
      max_age_seconds = 3000
    },
  ]
}
