data "aws_iam_policy_document" "api_gateway_full_access" {
  statement {
    effect    = "Allow"
    actions   = ["apigateway:*"]
    resources = ["arn:aws:apigateway:${local.aws_region}::*"]
  }
}

resource "aws_iam_policy" "api_gateway_full_access" {
  name   = "terraform-${local.project}-${local.env}-api-gateway-policy"
  policy = data.aws_iam_policy_document.api_gateway_full_access.json
}

resource "aws_iam_role_policy_attachment" "api_gateway_full_access" {
  role       = aws_iam_role.instance.name
  policy_arn = aws_iam_policy.api_gateway_full_access.arn
}
