locals {
  admin_web_bucket_name       = "makan-go-admin-web"
  spot_submission_bucket_name = "makan-go-spot-submissions"
  spot_submission_prefix      = "submissions/"
  origin_id                   = "spot-submission-photos-prod"
}

resource "aws_s3_bucket" "admin_web" {
  bucket = local.admin_web_bucket_name
}

resource "aws_s3_bucket_ownership_controls" "admin_web" {
  bucket = aws_s3_bucket.admin_web.id

  rule {

    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "admin_web" {
  bucket                  = aws_s3_bucket.admin_web.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "admin_web" {
  bucket = aws_s3_bucket.admin_web.id

  rule {
    blocked_encryption_types = ["NONE"]
    bucket_key_enabled       = false
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "admin_web" {
  bucket = aws_s3_bucket.admin_web.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_cloudfront_response_headers_policy" "admin_web_security_headers" {
  name = "${local.admin_web_bucket_name}-security-headers"

  security_headers_config {
    strict_transport_security {
      access_control_max_age_sec = 31536000
      include_subdomains         = true
      override                   = true
      preload                    = false
    }
  }
}

data "aws_iam_policy_document" "admin_web_bucket_policy" {
  statement {
    sid     = "AllowCloudFrontAccess"
    effect  = "Allow"
    actions = ["s3:GetObject"]

    resources = [
      "${aws_s3_bucket.admin_web.arn}/*"
    ]

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.admin_web.arn]
    }
  }

  statement {
    sid     = "DenyInsecureTransport"
    effect  = "Deny"
    actions = ["s3:*"]

    resources = [
      aws_s3_bucket.admin_web.arn,
      "${aws_s3_bucket.admin_web.arn}/*"
    ]

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_policy" "admin_web" {
  bucket = aws_s3_bucket.admin_web.id
  policy = data.aws_iam_policy_document.admin_web_bucket_policy.json

  depends_on = [
    aws_s3_bucket_public_access_block.admin_web
  ]
}

resource "aws_s3_bucket" "spot_submission_photos" {
  bucket = local.spot_submission_bucket_name
}

resource "aws_s3_bucket_ownership_controls" "spot_submission_photos" {
  bucket = aws_s3_bucket.spot_submission_photos.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "spot_submission_photos" {
  bucket                  = aws_s3_bucket.spot_submission_photos.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "spot_submission_photos" {
  bucket = aws_s3_bucket.spot_submission_photos.id

  rule {
    blocked_encryption_types = ["NONE"]
    bucket_key_enabled       = false
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "spot_submission_photos" {
  bucket = aws_s3_bucket.spot_submission_photos.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "spot_submission_photos" {
  bucket = aws_s3_bucket.spot_submission_photos.id

  rule {
    id     = "expire-old-uploads"
    status = "Enabled"

    filter {
      prefix = local.spot_submission_prefix
    }

    expiration {
      days = 365
    }
  }
}

resource "aws_s3_bucket_cors_configuration" "spot_submission_photos" {
  bucket = aws_s3_bucket.spot_submission_photos.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "HEAD", "POST", "PUT"]
    allowed_origins = ["*"]
    expose_headers  = []
    max_age_seconds = 3000
  }
}

resource "aws_cloudfront_response_headers_policy" "spot_submission_security_headers" {
  name = "${local.spot_submission_bucket_name}-security-headers"

  security_headers_config {
    strict_transport_security {
      access_control_max_age_sec = 31536000
      include_subdomains         = true
      override                   = true
      preload                    = false
    }
  }
}

data "aws_iam_policy_document" "spot_submission_bucket_policy" {
  statement {
    sid     = "AllowCloudFrontAccess"
    effect  = "Allow"
    actions = ["s3:GetObject"]

    resources = [
      "${aws_s3_bucket.spot_submission_photos.arn}/*"
    ]

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.spot_submission.arn]
    }
  }

  statement {
    sid     = "DenyInsecureTransport"
    effect  = "Deny"
    actions = ["s3:*"]

    resources = [
      aws_s3_bucket.spot_submission_photos.arn,
      "${aws_s3_bucket.spot_submission_photos.arn}/*"
    ]

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_policy" "spot_submission_photos" {
  bucket = aws_s3_bucket.spot_submission_photos.id
  policy = data.aws_iam_policy_document.spot_submission_bucket_policy.json

  depends_on = [
    aws_s3_bucket_public_access_block.spot_submission_photos
  ]
}