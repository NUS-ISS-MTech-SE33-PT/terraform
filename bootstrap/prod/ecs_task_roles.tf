locals {
  ecs_task_role_services = {
    "review-service" = {
      table_arns = ["arn:aws:dynamodb:${local.aws_region}:${local.account_id}:table/reviews-prod"]
    }
  }
}

resource "aws_iam_role" "ecs_task_roles" {
  for_each = local.ecs_task_role_services
  name     = "${each.key}-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "ecs-tasks.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "iam_passrole_policies" {
  for_each = local.ecs_task_role_services
  name     = "${each.key}-iam-passrole-policy"
  role     = aws_iam_role.ecs_task_roles[each.key].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["iam:PassRole"]
        Resource = [
          aws_iam_role.ecs_task_execution_role.arn,
          aws_iam_role.ecs_task_roles[each.key].arn,
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy" "dynamodb_policies" {
  for_each = local.ecs_task_role_services
  name     = "${each.key}-dynamodb-policy"
  role     = aws_iam_role.ecs_task_roles[each.key].id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:BatchGetItem",
          "dynamodb:Query",
          "dynamodb:Scan",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem"
        ]
        Resource = [for arn in each.value.table_arns : "${arn}*"]
      }
    ]
  })
}