resource "aws_iam_policy" "kms_iam_policy" {
  name   = "terraform-kms-${var.tags.environment}-policy"
  policy = data.aws_iam_policy_document.kms_iam_policy_document.json
  tags   = var.tags
}

resource "aws_iam_role_policy_attachment" "terraform_kms" {
  role       = var.role_name
  policy_arn = aws_iam_policy.kms_iam_policy.arn
}

data "aws_caller_identity" "current" {}

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

  statement {
    effect = "Allow"

    actions = [
      "kms:DescribeKey",
      "kms:GetKeyPolicy",
      "kms:GetKeyRotationStatus",
      "kms:ListResourceTags",
      "kms:ScheduleKeyDeletion",
      "kms:CancelKeyDeletion",
      "kms:EnableKeyRotation",
      "kms:DisableKeyRotation",
      "kms:UpdateKeyDescription",
      "kms:TagResource",
      "kms:UntagResource",
    ]

    resources = [
      "arn:aws:kms:${var.aws_region}:${data.aws_caller_identity.current.account_id}:alias/terraform-kms-management-${var.tags.environment}"
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = [var.aws_region]
    }
  }

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

  #   condition {
  #     test     = "StringEquals"
  #     variable = "aws:ResourceTag/ManagedBy"
  #     values   = ["terraform"]
  #   }
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

resource "aws_kms_key" "instance" {
  deletion_window_in_days  = 7
  enable_key_rotation      = true
  customer_master_key_spec = "SYMMETRIC_DEFAULT"
  key_usage                = "ENCRYPT_DECRYPT"
}
