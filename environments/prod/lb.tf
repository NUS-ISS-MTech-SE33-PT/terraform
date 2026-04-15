locals {
  services = {
    review_service = {
      name    = "review-service"
      tg_name = "review-svc-tg"
    }
    spot_service = {
      name    = "spot-service"
      tg_name = "spot-service-target-group"
    }
    spot_submission_service = {
      name    = "spot-submission-service"
      tg_name = "spot-sub-svc-tg"
    }
  }
}

resource "aws_lb" "service" {
  for_each = local.services

  name               = "${each.value.name}-nlb"
  internal           = true
  load_balancer_type = "network"
  subnets            = aws_subnet.ecs_subnet[*].id
}

resource "aws_lb_target_group" "service" {
  for_each = local.services

  name        = each.value.tg_name
  port        = 8080
  protocol    = "TCP"
  vpc_id      = aws_vpc.ecs_vpc.id
  target_type = "ip"

  health_check {
    protocol            = "TCP"
    port                = "traffic-port"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 10
    timeout             = 5
  }
}

resource "aws_lb_listener" "service" {
  for_each = local.services

  load_balancer_arn = aws_lb.service[each.key].arn
  port              = 80
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.service[each.key].arn
  }
}
