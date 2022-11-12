# alb - will be on the public subnet and will forward the requests to the ECS service
resource "aws_alb" "main" {
  name            = format("%s-%s-ALB", var.app_name, var.environment)
  subnets         = values(aws_subnet.public)[*].id
  security_groups = [aws_security_group.lb.id]
}

resource "aws_alb_target_group" "app" {
  name        = format("%s-%s-TG-ALB", var.app_name, var.environment)
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  # If ALB check failed, ALB will make target group unhealthy and as a result, your container will be killed
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
