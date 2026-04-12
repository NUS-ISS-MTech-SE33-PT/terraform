data "aws_iam_policy_document" "bootstrap_policy_document" {
  statement {
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [local.bucket_arn]

    condition {
      test     = "StringEquals"
      variable = "s3:prefix"
      values   = ["${local.env}/terraform.tfstate"]
    }
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:GetObject"
    ]
    resources = ["${local.bucket_arn}/${local.env}/terraform.tfstate"]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject"
    ]
    resources = ["${local.bucket_arn}/${local.env}/terraform.tfstate.tflock"]
  }
}

resource "aws_iam_policy" "instance" {
  name   = "terraform-${local.project}-${local.env}-bootstrap-policy"
  policy = data.aws_iam_policy_document.bootstrap_policy_document.json
}

resource "aws_iam_role_policy_attachment" "instance" {
  role       = aws_iam_role.instance.name
  policy_arn = aws_iam_policy.instance.arn
}
