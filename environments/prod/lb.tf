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

moved {
  from = aws_lb.review_service_network_load_balancer
  to   = aws_lb.service["review_service"]
}

moved {
  from = aws_lb.spot_service_network_load_balancer
  to   = aws_lb.service["spot_service"]
}

moved {
  from = aws_lb.spot_submission_service_network_load_balancer
  to   = aws_lb.service["spot_submission_service"]
}

moved {
  from = aws_lb_target_group.review_service_target_group
  to   = aws_lb_target_group.service["review_service"]
}

moved {
  from = aws_lb_target_group.spot_service_target_group
  to   = aws_lb_target_group.service["spot_service"]
}

moved {
  from = aws_lb_target_group.spot_submission_service_target_group
  to   = aws_lb_target_group.service["spot_submission_service"]
}

moved {
  from = aws_lb_listener.review_service_network_load_balancer_listener
  to   = aws_lb_listener.service["review_service"]
}

moved {
  from = aws_lb_listener.spot_service_network_load_balancer_listener
  to   = aws_lb_listener.service["spot_service"]
}

moved {
  from = aws_lb_listener.spot_submission_service_network_load_balancer_listener
  to   = aws_lb_listener.service["spot_submission_service"]
}
