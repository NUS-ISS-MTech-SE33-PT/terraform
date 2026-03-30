resource "aws_iam_policy" "kms_iam_policy" {
  name        = "terraform-kms-management-${var.tags.environment}"
  description = "Allows the Terraform CI role to create and manage KMS keys"
  policy      = data.aws_iam_policy_document.kms_iam_policy_document.json
  tags        = var.tags
}

resource "aws_iam_role_policy_attachment" "terraform_kms" {
  role       = var.role_name
  policy_arn = aws_iam_policy.kms_iam_policy.arn
}

data "aws_iam_policy_document" "kms_iam_policy_document" {
  statement {
    effect = "Allow"

    actions = [
      "kms:CreateKey"
    ]

    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = [var.aws_region]
    }
  }

  #   statement {
  #     effect = "Allow"

  #     actions = [
  #       "kms:CreateKey",
  #       "kms:DescribeKey",
  #       "kms:GetKeyPolicy",
  #       "kms:GetKeyRotationStatus",
  #       "kms:ListResourceTags",
  #       "kms:ScheduleKeyDeletion",
  #       "kms:CancelKeyDeletion",
  #       "kms:EnableKeyRotation",
  #       "kms:DisableKeyRotation",
  #       "kms:UpdateKeyDescription",
  #       "kms:TagResource",
  #       "kms:UntagResource",
  #     ]

  #     # Scope CreateKey to * (required by AWS — no resource ARN exists before creation).
  #     # All other actions are scoped to keys tagged as managed by Terraform.
  #     resources = ["*"]

  #     condition {
  #       test     = "StringEquals"
  #       variable = "aws:RequestedRegion"
  #       values   = [var.aws_region]
  #     }
  #   }

  #   statement {
  #     sid    = "AllowKMSKeyUsage"
  #     effect = "Allow"

  #     actions = [
  #       "kms:Encrypt",
  #       "kms:Decrypt",
  #       "kms:ReEncrypt*",
  #       "kms:GenerateDataKey*",
  #       "kms:CreateGrant",
  #       "kms:ListGrants",
  #       "kms:RevokeGrant",
  #     ]

  #     resources = ["*"]

  #     condition {
  #       test     = "StringEquals"
  #       variable = "aws:ResourceTag/ManagedBy"
  #       values   = ["terraform"]
  #     }
  #   }

  #   statement {
  #     sid    = "AllowKMSAliasManagement"
  #     effect = "Allow"

  #     actions = [
  #       "kms:CreateAlias",
  #       "kms:DeleteAlias",
  #       "kms:UpdateAlias",
  #       "kms:ListAliases",
  #     ]

  #     # Alias ARNs require both the alias resource and the key resource
  #     resources = [
  #       "arn:aws:kms:${var.aws_region}:${var.account_id}:alias/*",
  #       "arn:aws:kms:${var.aws_region}:${var.account_id}:key/*",
  #     ]
  #   }
}
