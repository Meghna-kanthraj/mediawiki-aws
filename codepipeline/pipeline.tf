resource "aws_codepipeline" "mediawiki_pipeline" {
  name     = "mediawiki-pipeline"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = "your-s3-bucket-name"
    type     = "S3"
  }

  stage {
    name = "Source" #Source: Listens to changes in a GitHub repository

    action {
      name             = "SourceAction"
      category         = "Source"
      owner            = "ThirdParty"
      provider         = "GitHub"
      version          = "1"
      output_artifacts = ["SourceArtifact"]

      configuration = {
        Owner                  = var.github_repository_owner
        Repo                   = var.github_repository_name
        Branch                 = var.github_branch
        OAuthToken             = var.github_oauth_token
        PollForSourceChanges   = "false"
      }
    }
  }

  stage {
    name = "Build" # Builds the Docker image using AWS CodeBuild.

    action {
      name            = "BuildAction"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      version         = "1"
      input_artifacts = ["SourceArtifact"]
      output_artifacts = ["BuildArtifact"]

      configuration = {
        ProjectName = aws_codebuild_project.build_project.name
      }
    }
  }

  stage {
    name = "Deploy" #Deploys the Docker image to the EKS cluster using a custom CodeDeploy action

    action {
      name            = "DeployAction"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "CodeDeployToEKS"
      version         = "1"
      input_artifacts = ["BuildArtifact"]

      configuration = {
        ClusterName   = var.eks_cluster_name
        AppName       = "mediawiki"
        Namespace     = "default"
        ServiceName   = "mediawiki-service"
        Image         = "${aws_ecr_repository.mediawiki.repository_url}:latest"
      }
    }
  }
}
