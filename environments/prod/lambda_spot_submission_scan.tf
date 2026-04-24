data "aws_iam_role" "spot_submission_scan_lambda_role" {
  name = "spot-submission-scan-lambda-role"
}

data "archive_file" "spot_submission_scan_lambda" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/spot_submission_scan"
  output_path = "/tmp/spot-submission-scan-lambda.zip"
}

locals {
  spot_submission_scan_lambda_name = "makan-go-prod-spot-submission-scan"
  clamav_layer_s3_bucket           = "makan-go-lambda-artifacts-921142537307-ap-southeast-1"
  clamav_layer_s3_key              = "clamav-layer.zip"
  clamav_layer_s3_version          = "M3YzAFyTlrUaZqrvQ1E9PD3N4T42VHIV"
}

resource "aws_cloudwatch_log_group" "spot_submission_scan_lambda" {
  name              = "/aws/lambda/${local.spot_submission_scan_lambda_name}"
  retention_in_days = 14
  tags              = local.common_tags
}

resource "aws_lambda_layer_version" "clamav" {
  layer_name          = "makan-go-prod-clamav"
  description         = "ClamAV binaries and shared libraries for the spot-submission scanner."
  s3_bucket           = local.clamav_layer_s3_bucket
  s3_key              = local.clamav_layer_s3_key
  s3_object_version   = local.clamav_layer_s3_version
  compatible_runtimes = ["python3.12"]
}

resource "aws_lambda_function" "spot_submission_scan" {
  function_name = local.spot_submission_scan_lambda_name
  description   = "Scans newly uploaded spot-submission images and tags them with scan-status."
  role          = data.aws_iam_role.spot_submission_scan_lambda_role.arn
  runtime       = "python3.12"
  handler       = "scanner.handler"
  filename      = data.archive_file.spot_submission_scan_lambda.output_path

  source_code_hash = data.archive_file.spot_submission_scan_lambda.output_base64sha256
  timeout          = 300
  memory_size      = 2048
  architectures    = ["x86_64"]
  layers           = [aws_lambda_layer_version.clamav.arn]

  ephemeral_storage {
    size = 2048
  }

  environment {
    variables = {
      BUCKET_NAME                = module.s3_spot_submission_photos.bucket
      KEY_PREFIX                 = "submissions/"
      SCAN_STATUS_TAG_KEY        = "scan-status"
      CLEAN_SCAN_STATUS          = "clean"
      INFECTED_SCAN_STATUS       = "infected"
      ERROR_SCAN_STATUS          = "error"
      CLAMSCAN_PATH              = "/opt/bin/clamscan"
      FRESHCLAM_PATH             = "/opt/bin/freshclam"
      CLAMAV_DATABASE_DIR        = "/tmp/clamav-db"
      CLAMSCAN_TIMEOUT_SECONDS   = "120"
      FRESHCLAM_TIMEOUT_SECONDS  = "240"
      FRESHCLAM_COOLDOWN_MINUTES = "360"
      LD_LIBRARY_PATH            = "/opt/lib64:/opt/lib:/lib64:/usr/lib64"
      PATH                       = "/opt/bin:/usr/local/bin:/usr/bin:/bin"
      SSL_CERT_FILE              = "/opt/certs/ca-bundle.crt"
    }
  }

  tags = local.common_tags

  depends_on = [aws_cloudwatch_log_group.spot_submission_scan_lambda]
}

resource "aws_lambda_permission" "spot_submission_scan_s3" {
  statement_id  = "AllowExecutionFromSpotSubmissionBucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.spot_submission_scan.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = module.s3_spot_submission_photos.arn
}

resource "aws_s3_bucket_notification" "spot_submission_scan" {
  bucket = module.s3_spot_submission_photos.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.spot_submission_scan.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "submissions/"
  }

  depends_on = [aws_lambda_permission.spot_submission_scan_s3]
}
