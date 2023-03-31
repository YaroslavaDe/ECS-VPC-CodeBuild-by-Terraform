![schema_project_3](https://user-images.githubusercontent.com/107043798/201763473-f4e03f1d-ee8d-4233-9190-0c6d5fc16200.jpg)

This solution includes Continuous deployment based on "Infrastructure as a code". It consists of Python Flask based web-application, Terraform modules to create infrastructure and configuration to make deployment easier.

The solution creates an ECR repo, builds initial Docker image, creates a ECS Cluster, runs application on ECS Cluster and sets up Codebuild job which will start build and deploy by every commit to particular git branch ( "dev" by default).

The repo contains the next components:

* Application itself
* Terraform modules:
    * ECS - Creates a ECS Cluster and related services
    * Codebuild - Creates an AWS Codebuild job which starts automatically when code pushed to "dev" branch
    * ECR - Creates an Elastic Container repository
    * init-build - Builds and deploys initial image to ECR when new repository is created

> /project/config//buildspec.yml - Pipeline file for AWS Codebuild

### Infrastructure deployment
Now everything is ready to deploy infrastructure. Run the next command:

`terraform plan --var-file=./config/dev.tfvars` 

If plan creation succeeded, apply it:

`terraform apply --var-file=./config/dev.tfvars`

Terraform will create the next resources:

* ECR repository
* Build an image and push it to a new repo
* ECS Cluster
* Codebuild job
When Terraform finish resources creation, you can commit updated code to "dev" branch and build will be started after a new commit pushed to git repo.

You can deploy infrastructure step by step. If you want to do it, you should use Terraform targeting.

It can be done like this. First, ECR should be created:

`terraform apply -target=module.ecr --var-file=./config/dev.tfvars`

Then you should run initial image build:

`terraform apply -target=module.init-build --var-file=./config/dev.tfvars`

Then deploy ECS Cluster:

`terraform apply -target=module.ecs-cluster --var-file=./config/dev.tfvars`

And finally, create Codebuild job:

`terraform apply -target=module.codebuild --var-file=./config/dev.tfvars`

Destroy modules one by one in reverse order of deployment:

`terraform destroy -target=module.codebuild --var-file=./config/dev.tfvars`

`terraform destroy -target=module.ecs-cluster --var-file=./config/dev.tfvars`

`terraform destroy -target=module.init-build --var-file=./config/dev.tfvars`

`terraform destroy -target=module.ecr --var-file=./config/dev.tfvars`

S3 Bucket can be deleted manually using AWS console or AWS CLI. 