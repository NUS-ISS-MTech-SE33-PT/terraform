data "aws_iam_policy_document" "ecr_full_access" {
  statement {
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken"
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "ecr:CreateRepository",
      "ecr:DeleteRepository",
      "ecr:DescribeRepositories",
      "ecr:GetRepositoryPolicy",
      "ecr:SetRepositoryPolicy",
      "ecr:DeleteRepositoryPolicy",
      "ecr:ListTagsForResource",
      "ecr:TagResource",
      "ecr:UntagResource",
      "ecr:PutImageScanningConfiguration",
      "ecr:PutImageTagMutability",
      "ecr:GetLifecyclePolicy",
      "ecr:PutLifecyclePolicy",
      "ecr:DeleteLifecyclePolicy",
    ]
    resources = ["arn:aws:ecr:${local.aws_region}:${local.account_id}:repository/*"]
  }
}

resource "aws_iam_policy" "ecr_full_access" {
  name   = "terraform-${local.project}-${local.env}-ecr-policy"
  policy = data.aws_iam_policy_document.ecr_full_access.json
}

resource "aws_iam_role_policy_attachment" "ecr_full_access" {
  role       = aws_iam_role.instance.name
  policy_arn = aws_iam_policy.ecr_full_access.arn
}
