provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}

terraform {
  backend "s3" {
    encrypt = true
    bucket  = "project-terraform-vpc-subnets-alb"
    region  = "eu-west-2"
    key     = "state"
  }
  required_providers {
    aws = {
      version = "~> 3.35"
    }
  }
}
