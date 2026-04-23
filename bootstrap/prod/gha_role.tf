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

# --- review-service CD role ---

data "aws_iam_policy_document" "review_service_cd_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Federated"
      identifiers = ["arn:aws:iam::${local.account_id}:oidc-provider/token.actions.githubusercontent.com"]
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
      values   = ["repo:NUS-ISS-MTech-SE33-PT/review-service:environment:production"]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:job_workflow_ref"
      values   = ["NUS-ISS-MTech-SE33-PT/review-service/.github/workflows/cd.yml@refs/heads/main"]
    }
  }
}

resource "aws_iam_role" "review_service_cd" {
  name               = "github-actions-review-service-${local.env}-role"
  assume_role_policy = data.aws_iam_policy_document.review_service_cd_assume_role.json
}

data "aws_iam_policy_document" "review_service_cd_policy" {
  statement {
    effect    = "Allow"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:PutImage",
    ]
    resources = ["arn:aws:ecr:${local.aws_region}:${local.account_id}:repository/makango-review-service"]
  }

  statement {
    effect = "Allow"
    actions = [
      "ecs:DescribeServices",
      "ecs:UpdateService",
    ]
    resources = ["arn:aws:ecs:${local.aws_region}:${local.account_id}:service/prod-cluster/review-service"]
  }
}

resource "aws_iam_policy" "review_service_cd" {
  name   = "github-actions-review-service-${local.env}-policy"
  policy = data.aws_iam_policy_document.review_service_cd_policy.json
}

resource "aws_iam_role_policy_attachment" "review_service_cd" {
  role       = aws_iam_role.review_service_cd.name
  policy_arn = aws_iam_policy.review_service_cd.arn
}
