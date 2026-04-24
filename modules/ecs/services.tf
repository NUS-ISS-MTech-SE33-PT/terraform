resource "aws_ecs_task_definition" "service" {
  for_each = var.services

  family                   = "${each.value.name}-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = each.value.cpu
  memory                   = each.value.memory
  execution_role_arn       = var.execution_role_arn
  task_role_arn            = each.value.task_role_arn
  tags                     = var.tags

  container_definitions = jsonencode([
    {
      name      = "${each.value.name}-container"
      image     = each.value.image
      essential = true
      portMappings = [
        {
          containerPort = 8080
          protocol      = "tcp"
        }
      ]
      environment = each.value.environment
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = each.value.log_group_name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = each.value.name
        }
      }
    }
  ])
}

resource "aws_ecs_service" "service" {
  for_each = var.services

  name            = each.value.name
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.service[each.key].arn
  desired_count   = each.value.desired_count
  launch_type     = "FARGATE"
  tags            = var.tags

  network_configuration {
    subnets          = var.subnet_ids
    assign_public_ip = true
    security_groups  = length(each.value.security_group_ids) > 0 ? each.value.security_group_ids : var.security_group_ids
  }

  load_balancer {
    target_group_arn = each.value.target_group_arn
    container_name   = "${each.value.name}-container"
    container_port   = 8080
  }
}
