# mediawiki-aws

# MediaWiki Deployment on Amazon EKS

This project provides infrastructure as code (IaC) for deploying the MediaWiki application on Amazon Elastic Kubernetes Service (EKS) using Terraform and AWS CloudFormation. It includes a CI/CD pipeline setup using AWS CodePipeline, AWS CodeBuild, and AWS CodeDeploy.

## Prerequisites

- AWS CLI installed and configured
- Terraform installed
- GitHub repository for MediaWiki source code
- S3 bucket for CodePipeline artifacts
- IAM roles for CodePipeline, CodeBuild, and CodeDeploy

## Infrastructure Setup

### 1. Create EKS Cluster using Terraform

1. Create a file named `eks-cluster.tf` with the following content:

    ```hcl
    provider "aws" {
      region = "your_aws_region"
    }

    module "eks_cluster" {
      source            = "terraform-aws-modules/eks/aws"
      cluster_name      = "your_eks_cluster_name"
      cluster_version   = "1.20"
      subnets           = ["subnet-xxxxxx", "subnet-xxxxxx", "subnet-xxxxxx"]
      vpc_id            = "your_vpc_id"
      node_groups       = {
        eks_nodes = {
          desired_capacity = 2
          max_capacity     = 10
          min_capacity     = 1
          instance_type    = "t2.medium"
          key_name         = "your_key_pair_name"
          ami_type         = "AL2_x86_64"
          kubelet_extra_args = "--cloud-provider=aws"
        }
      }
    }
    ```

2. Initialize Terraform and apply the configuration:

    ```sh
    terraform init
    terraform apply
    ```

### 2. Deploy MediaWiki Application using Terraform

1. Create a file named `mediawiki-deployment.tf` with the following content:

    ```hcl
    provider "kubernetes" {
      config_context_cluster = "your_eks_cluster_name"
    }

    resource "kubernetes_deployment" "mediawiki" {
      metadata {
        name = "mediawiki"
        labels = {
          app = "mediawiki"
        }
      }

      spec {
        replicas = 1

        selector {
          match_labels = {
            app = "mediawiki"
          }
        }

        template {
          metadata {
            labels = {
              app = "mediawiki"
            }
          }

          spec {
            container {
              name  = "mediawiki"
              image = "mediawiki:latest"
              port {
                container_port = 80
              }
            }
          }
        }
      }
    }

    resource "kubernetes_service" "mediawiki" {
      metadata {
        name = "mediawiki"
      }

      spec {
        selector = {
          app = kubernetes_deployment.mediawiki.spec.0.template.0.metadata.0.labels["app"]
        }

        port {
          port        = 80
          target_port = 80
        }

        type = "LoadBalancer"
      }
    }
    ```

2. Apply the Terraform configuration:

    ```sh
    terraform apply
    ```

### 3. Create CodeBuild Project using CloudFormation

1. Create a file named `codebuild.yaml` with the following content:

    ```yaml
    AWSTemplateFormatVersion: '2010-09-09'
    Resources:
      CodeBuildProject:
        Type: 'AWS::CodeBuild::Project'
        Properties:
          Name: 'mediawiki-build-project'
          Description: 'Build project for MediaWiki application'
          ServiceRole: 'your-codebuild-service-role-arn'
          Artifacts:
            Type: 'NO_ARTIFACTS'
          Environment:
            Type: 'LINUX_CONTAINER'
            ComputeType: 'BUILD_GENERAL1_SMALL'
            Image: 'aws/codebuild/standard:5.0'
          Source:
            Type: 'CODEPIPELINE'
    ```

2. Deploy the CloudFormation stack:

    ```sh
    aws cloudformation create-stack --stack-name mediawiki-build --template-body file://codebuild.yaml
    ```

### 4. Setup CodePipeline using Terraform

1. Create a file named `codepipeline.tf` with the following content:

    ```hcl
    provider "aws" {
      region = "your_aws_region"
    }

    resource "aws_iam_role" "codepipeline_role" {
      name               = "codepipeline-role"
      assume_role_policy = jsonencode({
        Version   = "2012-10-17",
        Statement = [{
          Effect    = "Allow",
          Principal = {
            Service = "codepipeline.amazonaws.com"
          },
          Action    = "sts:AssumeRole"
        }]
      })
    }

    resource "aws_iam_policy_attachment" "codepipeline_policy_attachment" {
      name       = "codepipeline-policy-attachment"
      roles      = [aws_iam_role.codepipeline_role.name]
      policy_arn = "arn:aws:iam::aws:policy/AWSCodePipeline_FullAccess"
    }

    resource "aws_codepipeline" "mediawiki_pipeline" {
      name     = "mediawiki-pipeline"
      role_arn = aws_iam_role.codepipeline_role.arn

      artifact_store {
        location = "your-s3-bucket-name"
        type     = "S3"
      }

      stage {
        name = "Source"

        action {
          name             = "Source"
          category         = "Source"
          owner            = "ThirdParty"
          provider         = "GitHub"
          version          = "1"
          output_artifacts = ["source_output"]

          configuration = {
            Owner              = "your_github_username"
            Repo               = "your_repository_name"
            Branch             = "master"
            OAuthToken         = "your_github_oauth_token"
            PollForSourceChanges = "false"
          }
        }
      }

      stage {
        name = "Build"

        action {
          name             = "Build"
          category         = "Build"
          owner            = "AWS"
          provider         = "CodeBuild"
          input_artifacts  = ["source_output"]
          output_artifacts = ["build_output"]
          version          = "1"

          configuration = {
            ProjectName = "mediawiki-build-project"
          }
        }
      }

      stage {
        name = "Deploy"

        action {
          name             = "Deploy"
          category         = "Deploy"
          owner            = "AWS"
          provider         = "CodeDeploy"
          input_artifacts  = ["build_output"]
          version          = "1"

          configuration = {
            ApplicationName          = "mediawiki-app"
            DeploymentGroupName      = "mediawiki-deployment-group"
          }
        }
      }
    }
    ```

2. Initialize Terraform and apply the configuration:

    ```sh
    terraform init
    terraform apply
    ```

## Conclusion

You have now set up a complete CI/CD pipeline for deploying the MediaWiki application on Amazon EKS using Terraform and CloudFormation. The pipeline consists of three stages: Source (fetching code from GitHub), Build (building the code using CodeBuild), and Deploy (deploying the application using CodeDeploy).
