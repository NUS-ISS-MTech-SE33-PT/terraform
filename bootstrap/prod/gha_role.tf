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

resource "aws_iam_role" "instance" {
  name               = "github-actions-terraform-${local.env}-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy_document.json
}
