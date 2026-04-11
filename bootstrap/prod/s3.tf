data "aws_iam_policy_document" "s3_full_access" {
  statement {
    effect  = "Allow"
    actions = ["s3:*"]
    resources = [
      "arn:aws:s3:::${local.project}-*",
      "arn:aws:s3:::${local.project}-*/*",
    ]
  }
}

resource "aws_iam_policy" "s3_full_access" {
  name   = "terraform-${local.project}-${local.env}-s3-policy"
  policy = data.aws_iam_policy_document.s3_full_access.json
}

resource "aws_iam_role_policy_attachment" "s3_full_access" {
  role       = aws_iam_role.instance.name
  policy_arn = aws_iam_policy.s3_full_access.arn
}
