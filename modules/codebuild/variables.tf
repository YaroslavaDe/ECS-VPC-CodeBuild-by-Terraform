variable "aws_region" {
  description = "aws region"
}

variable "aws_profile" {
  description = "aws profile"
}

#variable "remote_state_bucket" {}

variable "repo_url" {
  description = "URL to Github repository to fetch source from"
}

variable "github_oauth_token" {
  description = "Github OAuth token with repo access permissions"
}

variable "environment" {
  type        = string
}

variable "app_name" {
  type        = string
}

variable "build_spec_file" {
  default = "buildspec.yml"
}

variable "vpc_id" {
  type        = string
  default     = null
  description = "The VPC ID that CodeBuild uses"
}

variable "subnets" {
  type        = list(string)
  default     = null
  description = "The subnet IDs that include resources used by CodeBuild"
}

variable "security_groups" {
  type        = list(string)
  default     = null
  description = "The security group IDs used by CodeBuild to allow access to resources in the VPC"
}

variable "env_vars" {
  description = <<EOF
Pass env vars for codebuild project(in native for codebuild project format)
Example:
env_vars = [
      {
        "name"  = "SOME_KEY1"
        "value" = "SOME_VALUE1"
      },
      {
        "name"  = "SOME_KEY2"
        "value" = "SOME_VALUE2"
      },
    ]
EOF

  default = []
}

locals {
  codebuild_project_name = "${var.app_name}-${var.environment}"
  description = "Codebuild for ${var.app_name} environment ${var.environment}"
}

variable "branch_pattern" {}

variable "git_trigger_event" {}

variable "codebuild_inbound" {
  type = map(object({
    port        = number
    protocol    = string
    cidr_blocks = list(string)
  }))
  
  default = {
    "80" = {
      port        = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
}

variable "codebuild_outbound" {
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

variable "compute_type_codebuild" {
  default = "BUILD_GENERAL1_SMALL"
}

variable "build_image_codebuild" {
  default = "aws/codebuild/standard:4.0"
}

### CODE BUILD ENVIORNMENT VARIABLES

# variable "codebuild_env_vars" {
#   description = "Environment var for CodeBuild"
#   type = object({
#     LOAD_VARS           = bool
#     EXPORT_PROJECT_NAME = string
#   })
#   default = {
#     LOAD_VARS           = true
#     EXPORT_PROJECT_NAME = "NAME_OF_PROJECT"
#   }
# }
locals {
  emails = ["yara.vikt@gmail.com"]
}