# security.tf

# ALB Security Group: Edit to restrict access to the application
resource "aws_security_group" "lb" {
  name        = "${var.app_name}-${var.environment}-lb-sg"
  description = "controls access to the ALB"
  vpc_id      = aws_vpc.main.id

  # ingress {
  #   protocol    = "tcp"
  #   from_port   = var.app_port
  #   to_port     = var.app_port
  #   cidr_blocks = ["0.0.0.0/0"]
  # }
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

  # egress {
  #   protocol    = "-1"
  #   from_port   = 0
  #   to_port     = 0
  #   cidr_blocks = ["0.0.0.0/0"]
  # }
}

# Traffic to the ECS cluster should only come from the ALB
resource "aws_security_group" "ecs_tasks" {
  name        = "${var.app_name}-${var.environment}-tasks-sg"
  description = "allow inbound access from the ALB only"
  vpc_id      = aws_vpc.main.id

  # ingress {
  #   protocol        = "tcp"
  #   from_port       = var.app_port
  #   to_port         = var.app_port
  #   security_groups = [aws_security_group.lb.id]
  # }
  dynamic "ingress" {
    for_each = var.app_inbound_ports

    content {
      from_port   = ingress.value.port
      to_port     = ingress.value.port
      protocol    = ingress.value.protocol
      #cidr_blocks = ingress.value.cidr_blocks
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
  # egress {
  #   protocol    = "-1"
  #   from_port   = 0
  #   to_port     = 0
  #   cidr_blocks = ["0.0.0.0/0"]
  # }
}
}

