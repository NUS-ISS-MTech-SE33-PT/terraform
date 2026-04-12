locals {
  admin_web_bucket_name = "makan-go-admin-web"
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
