environment = "dev"
app_name = "flaskapp"
aws_profile = "default"
aws_account = "218798394182"
aws_region = "eu-west-2"
image_tag = "0.0.1"
repo_url = "https://github.com/YaroslavaDe/ECS-VPC-CodeBuild-by-Terraform/"
branch_pattern = "^refs/heads/main$"
git_trigger_event = "PUSH"
app_count = 1

vpc_cidr = "10.0.0.0/16"
private_subnet_CIDR = ["10.0.3.0/24", "10.0.4.0/24"]
public_subnet_CIDR  = ["10.0.1.0/24", "10.0.2.0/24"]
