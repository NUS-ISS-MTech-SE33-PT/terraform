data "aws_iam_role" "ecs_task_execution_role" {
  name = "ecs-task-execution-role"
}

data "aws_iam_role" "review_service_task_role" {
  name = "review-service-ecs-task-role"
}

data "aws_iam_role" "spot_service_task_role" {
  name = "spot-service-ecs-task-role"
}

data "aws_iam_role" "spot_submission_service_task_role" {
  name = "spot-submission-service-ecs-task-role"
}

module "ecs" {
  source = "../../modules/ecs"

  cluster_name       = "prod-cluster"
  execution_role_arn = data.aws_iam_role.ecs_task_execution_role.arn
  aws_region         = local.aws_region
  subnet_ids         = aws_subnet.ecs_subnet[*].id
  security_group_ids = [aws_security_group.ecs_sg.id]
  tags               = local.common_tags

  services = {
    review_service = {
      name             = "review-service"
      image            = "${aws_ecr_repository.services["makango-review-service"].repository_url}:latest"
      task_role_arn    = data.aws_iam_role.review_service_task_role.arn
      target_group_arn = aws_lb_target_group.service["review_service"].arn
      log_group_name   = module.cloudwatch.log_groups["${local.common_tags.project}/${local.common_tags.environment}/review-service"].name
      environment = [
        { name = "HTTP_PORTS", value = "8080" },
        { name = "ReviewPrice__Max", value = "10000" },
      ]
    }
    spot_service = {
      name             = "spot-service"
      image            = "${aws_ecr_repository.services["makango-spot-service"].repository_url}:latest"
      task_role_arn    = data.aws_iam_role.spot_service_task_role.arn
      target_group_arn = aws_lb_target_group.service["spot_service"].arn
      log_group_name   = module.cloudwatch.log_groups["${local.common_tags.project}/${local.common_tags.environment}/spot-service"].name
      environment = [
        { name = "HTTP_PORTS", value = "8080" },
      ]
    }
    spot_submission_service = {
      name             = "spot-submission-service"
      image            = "${aws_ecr_repository.services["makango-spot-submission-service"].repository_url}:latest"
      task_role_arn    = data.aws_iam_role.spot_submission_service_task_role.arn
      target_group_arn = aws_lb_target_group.service["spot_submission_service"].arn
      log_group_name   = module.cloudwatch.log_groups["${local.common_tags.project}/${local.common_tags.environment}/spot-submission-service"].name
      environment = [
        { name = "HTTP_PORTS", value = "8080" },
        { name = "SpotSubmissionStorage__BucketName", value = module.s3_spot_submission_photos.bucket },
        { name = "SpotSubmissionStorage__KeyPrefix", value = "submissions/" },
        { name = "SpotSubmissionStorage__UrlExpiryMinutes", value = "15" },
        { name = "SpotSubmissionStorage__PublicBaseUrl", value = "https://${module.cloudfront_spot_submission.domain_name}" },
        { name = "DynamoDb", value = module.dynamodb_spot_submissions.table_name },
        { name = "SpotsTable", value = module.dynamodb_spot_submissions.table_name },
      ]
    }
  }
}
