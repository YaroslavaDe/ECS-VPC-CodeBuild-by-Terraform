variable "aws_region" {
  description = "aws region"
}

variable "aws_profile" {
  description = "aws profile"
}

#variable "remote_state_bucket" {}

variable "vpc_cidr" {
  type = string
  description = "The CIDR block for the VPC"
}

variable "private_subnet_CIDR" {
  type    = list(string)
}
variable "public_subnet_CIDR" {
  type    = list(string)
}

variable "ecs_task_execution_role_name" {
  description = "ECS task execution role name"
  default = "TaskExecutionRole"
}

variable "ecs_task_role_name" {
  description = "ECS task role name"
  default = "TaskRole"
}

variable "ecs_auto_scale_role_name" {
  description = "ECS auto scale role Name"
  default = "AutoScaleRole"
}

variable "az_count" {
  description = "Number of AZs to cover in a given region"
  default     = "2"
}

variable "app_port" {
  description = "Port exposed by the docker image to redirect traffic to"
  default     = 80
}
variable "app_inbound_ports" {
  type = map(object({
    port        = number
    protocol    = string
    cidr_blocks = list(string)
  }))
  
  default = {
    "80" = {
      port        = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
}

variable "outbound_ports" {
  type = map(object({
    port        = number
    protocol    = string
    cidr_blocks = list(string)
  }))
  
  default = {
    "0" = {
      port        = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
}

variable "test_block" {
  type = list

  default = [{

    healthy_threshold   = 3
    interval            = 30
    protocol            = "HTTP"
    unhealthy_threshold = 2
    timeout             = 3
    path                = "/"
    matcher             = "200"
   }]
}

variable "app_count" {
  description = "Number of docker containers to run"
  default     = 1
}

# variable "health_check_path" {
#   default = "/"
# }

variable "fargate_cpu" {
  description = "Fargate instance CPU units to provision (1 vCPU = 1024 CPU units)"
  default     = "512"
}

variable "fargate_memory" {
  description = "Fargate instance memory to provision (in MiB)"
  default     = "1024"
}

variable "environment" {
  type = string
}

variable "ecr_repository_url" {
  type = string
}

variable "app_name" {
  type = string
}

variable "image_tag" {
  type = string
}

variable "taskdef_template" {
  default = "cdef_app.json.tpl"
}

locals {
  app_image = format("%s:%s", var.ecr_repository_url, var.image_tag)
}
