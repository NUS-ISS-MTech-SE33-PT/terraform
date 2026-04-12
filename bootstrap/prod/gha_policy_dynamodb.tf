data "aws_iam_policy_document" "dynamodb_full_access" {
  statement {
    effect = "Allow"
    actions = [
      "dynamodb:CreateTable",
      "dynamodb:DeleteTable",
      "dynamodb:DescribeTable",
      "dynamodb:DescribeTimeToLive",
      "dynamodb:DescribeContinuousBackups",
      "dynamodb:ListTagsOfResource",
      "dynamodb:TagResource",
      "dynamodb:UntagResource",
      "dynamodb:UpdateTable",
      "dynamodb:UpdateTimeToLive",
      "dynamodb:UpdateContinuousBackups",
    ]
    resources = ["arn:aws:dynamodb:${local.aws_region}:${local.account_id}:table/*"]
  }
}

resource "aws_iam_role_policy" "dynamodb_full_access" {
  name   = "terraform-${local.project}-${local.env}-dynamodb-policy"
  role   = aws_iam_role.instance.name
  policy = data.aws_iam_policy_document.dynamodb_full_access.json
}
