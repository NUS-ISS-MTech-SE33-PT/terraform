data "aws_iam_policy_document" "cloudfront_full_access" {
  statement {
    effect  = "Allow"
    actions = ["cloudfront:*"]
    resources = [
      "arn:aws:cloudfront::${local.account_id}:distribution/*",
      "arn:aws:cloudfront::${local.account_id}:origin-access-control/*",
    ]
  }
}

resource "aws_iam_policy" "cloudfront_full_access" {
  name   = "terraform-${local.project}-${local.env}-cloudfront-policy"
  policy = data.aws_iam_policy_document.cloudfront_full_access.json
}

resource "aws_iam_role_policy_attachment" "cloudfront_full_access" {
  role       = aws_iam_role.instance.name
  policy_arn = aws_iam_policy.cloudfront_full_access.arn
}
