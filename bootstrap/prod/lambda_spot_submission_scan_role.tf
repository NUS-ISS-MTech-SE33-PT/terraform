resource "aws_iam_role" "spot_submission_scan_lambda_role" {
  name = "spot-submission-scan-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "spot_submission_scan_lambda_policy" {
  name = "spot-submission-scan-lambda-policy"
  role = aws_iam_role.spot_submission_scan_lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${local.aws_region}:${local.account_id}:log-group:/aws/lambda/makan-go-prod-spot-submission-scan:*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectTagging",
          "s3:PutObjectTagging"
        ]
        Resource = "arn:aws:s3:::makan-go-spot-submissions/submissions/*"
      }
    ]
  })
}
