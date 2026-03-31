data "aws_iam_policy_document" "assume_role_policy_document" {
  statement {
    effect = "Allow"
    principals {
      type        = "Federated"
      identifiers = ["arn:aws:iam::921142537307:oidc-provider/token.actions.githubusercontent.com"]
    }
    actions = ["sts:AssumeRoleWithWebIdentity"]

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values = [
        "repo:NUS-ISS-MTech-SE33-PT/terraform:ref:refs/heads/main",
        "repo:NUS-ISS-MTech-SE33-PT/terraform:environment:${local.env}"
      ]
    }
  }
}

data "aws_iam_policy_document" "bootstrap_policy_document" {
  statement {
    effect = "Allow"
    actions = [
      "iam:CreatePolicy",
      "iam:TagPolicy"
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "iam:ListPolicyVersions",
      "iam:GetPolicyVersion",
      "iam:GetPolicy"
    ]
    resources = ["*"]
    condition {
      test     = "StringLike"
      variable = "iam:PolicyARN"
      values   = ["arn:aws:iam::${local.account_id}:policy/terraform-${local.env}-*"]
    }
  }

  statement {
    effect    = "Allow"
    actions   = ["iam:ListAttachedRolePolicies", ]
    resources = [aws_iam_role.instance.arn]
  }

  statement {
    effect = "Allow"
    actions = [
      "iam:AttachRolePolicy",
      "iam:DetachRolePolicy"
    ]
    resources = [aws_iam_role.instance.arn]
    condition {
      test     = "ArnNotLike"
      variable = "iam:PolicyARN"
      values   = ["arn:aws:iam::${local.account_id}:policy/${local.bootstrap_policy_name}"]
    }
  }

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

resource "aws_iam_role" "instance" {
  name               = "github-actions-terraform-${local.env}-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy_document.json
}

resource "aws_iam_policy" "instance" {
  name   = local.bootstrap_policy_name
  policy = data.aws_iam_policy_document.bootstrap_policy_document.json
}

resource "aws_iam_role_policy_attachment" "instance" {
  role       = aws_iam_role.instance.name
  policy_arn = aws_iam_policy.instance.arn
}