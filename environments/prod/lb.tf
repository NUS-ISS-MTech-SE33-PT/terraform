resource "aws_lb" "review_service_network_load_balancer" {
  name               = "review-service-nlb"
  internal           = true
  load_balancer_type = "network"
  subnets            = aws_subnet.ecs_subnet[*].id
}

resource "aws_lb_target_group" "review_service_target_group" {
  name        = "review-service-target-group"
  port        = 80
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

resource "aws_lb_listener" "review_service_network_load_balancer_listener" {
  load_balancer_arn = aws_lb.review_service_network_load_balancer.arn
  port              = 80
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.review_service_target_group.arn
  }
}

resource "aws_lb" "spot_service_network_load_balancer" {
  name               = "spot-service-nlb"
  internal           = true
  load_balancer_type = "network"
  subnets            = aws_subnet.ecs_subnet[*].id
}

resource "aws_lb_target_group" "spot_service_target_group" {
  name        = "spot-service-target-group"
  port        = 80
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

resource "aws_lb_listener" "spot_service_network_load_balancer_listener" {
  load_balancer_arn = aws_lb.spot_service_network_load_balancer.arn
  port              = 80
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.spot_service_target_group.arn
  }
}

resource "aws_lb" "spot_submission_service_network_load_balancer" {
  name               = "spot-submission-service-nlb"
  internal           = true
  load_balancer_type = "network"
  subnets            = aws_subnet.ecs_subnet[*].id
}

resource "aws_lb_target_group" "spot_submission_service_target_group" {
  name        = "spot-submission-service-tg"
  port        = 80
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

resource "aws_lb_listener" "spot_submission_service_network_load_balancer_listener" {
  load_balancer_arn = aws_lb.spot_submission_service_network_load_balancer.arn
  port              = 80
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.spot_submission_service_target_group.arn
  }
}
