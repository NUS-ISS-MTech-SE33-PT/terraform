resource "aws_ecs_cluster" "prod_cluster" {
  name = "prod-cluster"
}

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

resource "aws_ecs_task_definition" "review_service_task" {
  family                   = "review-service-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = data.aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = data.aws_iam_role.review_service_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "review-service-container"
      image     = "${aws_ecr_repository.review_service.repository_url}:latest"
      essential = true
      portMappings = [
        {
          containerPort = 8080
          protocol      = "tcp"
        }
      ]
      environment = [
        {
          name  = "HTTP_PORTS"
          value = "8080"
        },
        {
          name  = "ReviewPrice__Max"
          value = "10000"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "makan-go/prod/review-service"
          "awslogs-region"        = "ap-southeast-1"
          "awslogs-stream-prefix" = "review-service"
        }
      }
    }
  ])

}

resource "aws_ecs_service" "review_service" {
  name            = "review-service"
  cluster         = aws_ecs_cluster.prod_cluster.id
  task_definition = aws_ecs_task_definition.review_service_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = aws_subnet.ecs_subnet[*].id
    assign_public_ip = true
    security_groups  = [aws_security_group.ecs_sg.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.review_service_target_group.arn
    container_name   = "review-service-container"
    container_port   = 8080
  }
}

resource "aws_ecs_task_definition" "spot_service_task" {
  family                   = "spot-service-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = data.aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = data.aws_iam_role.spot_service_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "spot-service-container"
      image     = "${aws_ecr_repository.spot_service.repository_url}:latest"
      essential = true
      portMappings = [
        {
          containerPort = 8080
          protocol      = "tcp"
        }
      ]
      environment = [
        {
          name  = "HTTP_PORTS"
          value = "8080"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "makan-go/prod/spot-service"
          "awslogs-region"        = "ap-southeast-1"
          "awslogs-stream-prefix" = "spot-service"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "spot_service" {
  name            = "spot-service"
  cluster         = aws_ecs_cluster.prod_cluster.id
  task_definition = aws_ecs_task_definition.spot_service_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = aws_subnet.ecs_subnet[*].id
    assign_public_ip = true
    security_groups  = [aws_security_group.ecs_sg.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.spot_service_target_group.arn
    container_name   = "spot-service-container"
    container_port   = 8080
  }
}

resource "aws_ecs_task_definition" "spot_submission_service_task" {
  family                   = "spot-submission-service-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = data.aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = data.aws_iam_role.spot_submission_service_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "spot-submission-service-container"
      image     = "${aws_ecr_repository.spot_submission_service.repository_url}:latest"
      essential = true
      portMappings = [
        {
          containerPort = 8080
          protocol      = "tcp"
        }
      ]
      environment = [
        {
          name  = "HTTP_PORTS"
          value = "8080"
        },
        {
          name  = "SpotSubmissionStorage__BucketName"
          value = aws_s3_bucket.spot_submission_photos.bucket
        },
        {
          name  = "SpotSubmissionStorage__KeyPrefix"
          value = "submissions/"
        },
        {
          name  = "SpotSubmissionStorage__UrlExpiryMinutes"
          value = "15"
        },
        {
          name  = "SpotSubmissionStorage__PublicBaseUrl"
          value = "https://${aws_cloudfront_distribution.spot_submission.domain_name}"
        },
        {
          name  = "DynamoDb"
          value = aws_dynamodb_table.spot_submissions.name
        },
        {
          name  = "SpotsTable"
          value = aws_dynamodb_table.spot_submissions.name
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "makan-go/prod/spot-submission-service"
          "awslogs-region"        = "ap-southeast-1"
          "awslogs-stream-prefix" = "spot-submission-service"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "spot_submission_service" {
  name            = "spot-submission-service"
  cluster         = aws_ecs_cluster.prod_cluster.id
  task_definition = aws_ecs_task_definition.spot_submission_service_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = aws_subnet.ecs_subnet[*].id
    assign_public_ip = true
    security_groups  = [aws_security_group.ecs_sg.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.spot_submission_service_target_group.arn
    container_name   = "spot-submission-service-container"
    container_port   = 8080
  }
}
