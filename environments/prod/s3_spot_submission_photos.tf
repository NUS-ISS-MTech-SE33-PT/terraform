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

# --- Moved blocks (safe to remove after one successful apply) ---

moved {
  from = aws_s3_bucket.spot_submission_photos
  to   = module.s3_spot_submission_photos.aws_s3_bucket.this
}

moved {
  from = aws_s3_bucket_ownership_controls.spot_submission_photos
  to   = module.s3_spot_submission_photos.aws_s3_bucket_ownership_controls.this
}

moved {
  from = aws_s3_bucket_public_access_block.spot_submission_photos
  to   = module.s3_spot_submission_photos.aws_s3_bucket_public_access_block.this
}

moved {
  from = aws_s3_bucket_server_side_encryption_configuration.spot_submission_photos
  to   = module.s3_spot_submission_photos.aws_s3_bucket_server_side_encryption_configuration.this
}

moved {
  from = aws_s3_bucket_versioning.spot_submission_photos
  to   = module.s3_spot_submission_photos.aws_s3_bucket_versioning.this
}

moved {
  from = aws_s3_bucket_lifecycle_configuration.spot_submission_photos
  to   = module.s3_spot_submission_photos.aws_s3_bucket_lifecycle_configuration.this[0]
}

moved {
  from = aws_s3_bucket_cors_configuration.spot_submission_photos
  to   = module.s3_spot_submission_photos.aws_s3_bucket_cors_configuration.this[0]
}

moved {
  from = aws_s3_bucket_policy.spot_submission_photos
  to   = module.s3_spot_submission_photos.aws_s3_bucket_policy.this
}
