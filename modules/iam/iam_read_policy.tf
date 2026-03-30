resource "aws_iam_policy" "iam_read_policy" {
  name        = "terraform-iam-read-${var.tags.environment}"
  description = "Allows the Terraform CI role to read IAM policies managed by Terraform"
  policy      = data.aws_iam_policy_document.iam_read_policy_document.json
  tags        = var.tags
}

resource "aws_iam_role_policy_attachment" "terraform_iam_read" {
  role       = var.role_name
  policy_arn = aws_iam_policy.iam_read_policy.arn
}

data "aws_iam_policy_document" "iam_read_policy_document" {
  statement {
    sid    = "AllowGetTerraformManagedPolicies"
    effect = "Allow"

    actions = [
      "iam:GetPolicy",
      "iam:GetPolicyVersion",
    ]

    resources = [
      "arn:aws:iam::${var.account_id}:policy/terraform-kms-management-${var.tags.environment}",
    ]
  }
}