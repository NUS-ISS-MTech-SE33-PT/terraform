data "aws_iam_policy_document" "cognito_full_access" {
  statement {
    effect    = "Allow"
    actions   = ["cognito-idp:*"]
    resources = ["arn:aws:cognito-idp:${local.aws_region}:${local.account_id}:userpool/*"]
  }
}

resource "aws_iam_policy" "cognito_full_access" {
  name   = "terraform-${local.project}-${local.env}-cognito-policy"
  policy = data.aws_iam_policy_document.cognito_full_access.json
}

resource "aws_iam_role_policy_attachment" "cognito_full_access" {
  role       = aws_iam_role.instance.name
  policy_arn = aws_iam_policy.cognito_full_access.arn
}
