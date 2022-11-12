# to obtain the name of the AWS region configured on the provider
data "aws_region" "current" {}

resource "aws_security_group" "codebuild_sg" {
  name        = "allow_vpc_connectivity"
  description = "Allow Codebuild connectivity to all the resources within our VPC"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = var.codebuild_inbound

    content {
      from_port   = ingress.value.port
      to_port     = ingress.value.port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
    }
  }

  dynamic "egress" {
    for_each = var.codebuild_outbound

    content {
      from_port   = egress.value.port
      to_port     = egress.value.port
      protocol    = egress.value.protocol
      cidr_blocks = egress.value.cidr_blocks
    }
  }
}

# resource "aws_secretsmanager_secret" "gh_token" {
#   name        = "NEW_ACCESS_TOKEN"
#   description = "Gitgub credentials"
# }

# resource "aws_secretsmanager_secret_version" "gh_token" {
#   secret_id     = aws_secretsmanager_secret.gh_token.id
#   secret_string = var.github_oauth_token
# }

# CodeBuild Project
resource "aws_codebuild_project" "project" {
  name          = local.codebuild_project_name
  description   = local.description
  build_timeout = "120"
  service_role  = aws_iam_role.role.arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    # Build environment compute type                                                              
    # https://docs.aws.amazon.com/codebuild/latest/userguide/build-env-ref-compute-types.html
    compute_type = var.compute_type_codebuild # 4 GB memory, 2 vCPUs, 50 GB disk space

    # https://docs.aws.amazon.com/codebuild/latest/userguide/build-env-ref-available.html
    image = var.build_image_codebuild
    type  = "LINUX_CONTAINER"
    # The privileged flag must be set so that your project has the required Docker permissions
    privileged_mode = true

    # environment_variable {
    #   name  = "SECRETS_ID"
    #   value = aws_secretsmanager_secret.gh_token.arn
    # }
  }
  # dynamic "environment_variable" {
  #   for_each = var.codebuild_env_vars["LOAD_VARS"] != false ? var.codebuild_env_vars : {}
  #   content {
  #     name  = environment_variable.key
  #     value = environment_variable.value
  #   }
  # }

  source {
    buildspec           = var.build_spec_file
    type                = "GITHUB"
    location            = var.repo_url
    git_clone_depth     = 1
    report_build_status = "true"
  }

  source_version = var.branch_pattern

  logs_config {
    cloudwatch_logs {
      group_name  = "codebuild-dev-log-group"
      stream_name = "codebuild-dev-log-stream"
      status      = "ENABLED"
    }
  }

  # Removed due using cache from ECR
  # cache {
  #   type = "LOCAL"
  #   modes = ["LOCAL_DOCKER_LAYER_CACHE"]
  # }

  # https://docs.aws.amazon.com/codebuild/latest/userguide/vpc-support.html#enabling-vpc-access-in-projects
  # Access resources within our VPC
  // dynamic "vpc_config" {
  //   for_each = var.vpc_id == null ? [] : [var.vpc_id]
  //   content {
  //     vpc_id = var.vpc_id
  //     subnets = var.subnets
  //     security_group_ids = var.security_groups
  //   }
  // }
  vpc_config {
    vpc_id = var.vpc_id

    subnets = var.subnets

    security_group_ids = [aws_security_group.codebuild_sg.id]
  }
}

resource "aws_codebuild_webhook" "develop_webhook" {
  project_name = aws_codebuild_project.project.name

  # https://docs.aws.amazon.com/codebuild/latest/APIReference/API_WebhookFilter.html
  filter_group {
    filter {
      type    = "EVENT"
      pattern = var.git_trigger_event
    }

    filter {
      type    = "HEAD_REF"
      pattern = var.branch_pattern
    }
  }
}

resource "aws_sns_topic" "codebuild" {
  name = "codebuild-notifications"
}

data "aws_iam_policy_document" "notif_access" {
  statement {
    actions = ["sns:Publish"]

    principals {
      type = "Service"
      identifiers = [
        "codestar-notifications.amazonaws.com"
      ]
    }

    resources = [aws_sns_topic.codebuild.arn]
  }
}
resource "aws_sns_topic_policy" "default" {
  arn    = aws_sns_topic.codebuild.arn
  policy = data.aws_iam_policy_document.notif_access.json
}

resource "aws_codestarnotifications_notification_rule" "codebuild" {
  detail_type = "BASIC"

  event_type_ids = [
    "codebuild-project-build-phase-failure",
    "codebuild-project-build-state-failed",
    "codebuild-project-build-state-stopped",
    "codebuild-project-build-state-succeeded"
  ]

  name     = "sns-notification-rule-codebuild"
  resource = aws_codebuild_project.project.arn

  target {
    address = aws_sns_topic.codebuild.arn
  }
}

resource "aws_sns_topic_subscription" "email_subscription" {
  count     = length(local.emails)
  topic_arn = aws_sns_topic.codebuild.arn
  protocol  = "email"
  endpoint  = local.emails[count.index]
}
