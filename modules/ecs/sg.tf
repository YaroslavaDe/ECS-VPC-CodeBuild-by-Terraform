# ALB Security Group: Edit to restrict access to the application
resource "aws_security_group" "lb" {
  name        = "${var.app_name}-${var.environment}-lb-sg"
  description = "controls access to the ALB"
  vpc_id      = aws_vpc.main.id

  dynamic "ingress" {
    for_each = var.app_inbound_ports

    content {
      from_port   = ingress.value.port
      to_port     = ingress.value.port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
    }
  }

  dynamic "egress" {
    for_each = var.outbound_ports

    content {
      from_port   = egress.value.port
      to_port     = egress.value.port
      protocol    = egress.value.protocol
      cidr_blocks = egress.value.cidr_blocks
    }
  }
}

# Traffic to the ECS cluster should only come from the ALB
resource "aws_security_group" "ecs_tasks" {
  name        = "${var.app_name}-${var.environment}-tasks-sg"
  description = "allow inbound access from the ALB only"
  vpc_id      = aws_vpc.main.id

  dynamic "ingress" {
    for_each = var.app_inbound_ports

    content {
      from_port       = ingress.value.port
      to_port         = ingress.value.port
      protocol        = ingress.value.protocol
      security_groups = [aws_security_group.lb.id]
    }
  }

  dynamic "egress" {
    for_each = var.outbound_ports

    content {
      from_port   = egress.value.port
      to_port     = egress.value.port
      protocol    = egress.value.protocol
      cidr_blocks = egress.value.cidr_blocks
    }
  }
}
