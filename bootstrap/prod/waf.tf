data "aws_iam_policy_document" "waf_full_access" {
  statement {
    effect    = "Allow"
    actions   = ["wafv2:*"]
    resources = ["arn:aws:wafv2:us-east-1:${local.account_id}:global/webacl/*"]
  }
}

resource "aws_iam_policy" "waf_full_access" {
  name   = "terraform-${local.project}-${local.env}-waf-policy"
  policy = data.aws_iam_policy_document.waf_full_access.json
}

resource "aws_iam_role_policy_attachment" "waf_full_access" {
  role       = aws_iam_role.instance.name
  policy_arn = aws_iam_policy.waf_full_access.arn
}
