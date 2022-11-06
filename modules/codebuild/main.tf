# to obtain the name of the AWS region configured on the provider
data "aws_region" "current" {}

resource "aws_security_group" "codebuild_sg" {
  name        = "allow_vpc_connectivity"
  description = "Allow Codebuild connectivity to all the resources within our VPC"
  vpc_id      = var.vpc_id

  # ingress {
  #   from_port   = 0
  #   to_port     = 0
  #   protocol    = "-1"
  #   cidr_blocks = ["0.0.0.0/0"]
  # }

  # egress {
  #   from_port   = 0
  #   to_port     = 0
  #   protocol    = "-1"
  #   cidr_blocks = ["0.0.0.0/0"]
  # }
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

resource "null_resource" "import_source_credentials" {


  triggers = {
    github_oauth_token = var.github_oauth_token
  }

  # Imports the source repository credentials for an CodeBuild project that has its source code stored in a GitHub
  provisioner "local-exec" {
    command = <<EOF
      aws --region ${data.aws_region.current.name} codebuild import-source-credentials \
                                                             --token ${var.github_oauth_token} \
                                                             --server-type GITHUB \
                                                             --auth-type PERSONAL_ACCESS_TOKEN
EOF
  }
}

# CodeBuild Project
resource "aws_codebuild_project" "project" {
  depends_on    = [null_resource.import_source_credentials]
  name          = local.codebuild_project_name
  description   = local.description
  build_timeout = "120"
  service_role  = aws_iam_role.role.arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    # Build environment compute type                                                              https://docs.aws.amazon.com/codebuild/latest/userguide/build-env-ref-compute-types.html
    compute_type = var.compute_type_codebuild # 4 GB memory, 2 vCPUs, 50 GB disk space

    # https://docs.aws.amazon.com/codebuild/latest/userguide/build-env-ref-available.html
    image = var.build_image_codebuild
    type  = "LINUX_CONTAINER"
    # The privileged flag must be set so that your project has the required Docker permissions
    privileged_mode = true

    environment_variable {
      name  = "CI"
      value = "true"
    }
    # dynamic "environment_variable" {
    #   for_each = var.codebuild_env_vars["LOAD_VARS"] != false ? var.codebuild_env_vars : {}
    #   content {
    #     name  = environment_variable.key
    #     value = environment_variable.value
    #   }
    # }
  }

  source {
    buildspec           = var.build_spec_file
    type                = "GITHUB"
    location            = var.repo_url
    git_clone_depth     = 1
    report_build_status = "true"
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
