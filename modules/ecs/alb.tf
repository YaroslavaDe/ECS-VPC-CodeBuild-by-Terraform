# alb.tf

resource "aws_alb" "main" {
  #name            = "${var.app_name}-${var.environment}-lb"
  name = format("%s-%s-ALB", var.app_name, var.environment)
  #subnets         = aws_subnet.public.*.id
  subnets         = values(aws_subnet.public)[*].id
  security_groups = [aws_security_group.lb.id]
}

resource "aws_alb_target_group" "app" {
  #name        = "${var.app_name}-${var.environment}-tg"
  name        = format("%s-%s-TG-ALB", var.app_name, var.environment)
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  # health_check {
  #   healthy_threshold   = "3"
  #   interval            = "30"
  #   protocol            = "HTTP"
  #   matcher             = "200"
  #   timeout             = "3"
  #   path                = var.health_check_path
  #   unhealthy_threshold = "2"
  # }
  dynamic "health_check" {
    for_each = var.test_block

    content {
      healthy_threshold   = health_check.value.healthy_threshold
      interval            = health_check.value.interval
      matcher             = health_check.value.matcher
      path                = health_check.value.path
      protocol            = health_check.value.protocol
      timeout             = health_check.value.timeout
      unhealthy_threshold = health_check.value.unhealthy_threshold
    }
  }
}

# Redirect all traffic from the ALB to the target group
resource "aws_alb_listener" "front_end" {
  load_balancer_arn = aws_alb.main.id
  port              = var.app_port
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_alb_target_group.app.id
    type             = "forward"
  }
}

