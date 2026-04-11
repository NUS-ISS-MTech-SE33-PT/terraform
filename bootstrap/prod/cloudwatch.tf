data "aws_iam_policy_document" "cloudwatch_full_access" {
  statement {
    effect    = "Allow"
    actions   = ["logs:*"]
    resources = ["arn:aws:logs:${local.aws_region}:${local.account_id}:log-group:*"]
  }
}

resource "aws_iam_policy" "cloudwatch_full_access" {
  name   = "terraform-${local.project}-${local.env}-cloudwatch-policy"
  policy = data.aws_iam_policy_document.cloudwatch_full_access.json
}

resource "aws_iam_role_policy_attachment" "cloudwatch_full_access" {
  role       = aws_iam_role.instance.name
  policy_arn = aws_iam_policy.cloudwatch_full_access.arn
}
