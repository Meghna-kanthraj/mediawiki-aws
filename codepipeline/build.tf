resource "aws_codebuild_project" "build_project" {
  name = "mediawiki-build"

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:3.0"
    type                        = "LINUX_CONTAINER"
    privileged_mode             = true
    environment_variable        = {
      "AWS_ACCOUNT_ID"          = aws_caller_identity.current.account_id
      "AWS_REGION"              = var.aws_region
      "ECR_REPOSITORY_URI"      = aws_ecr_repository.mediawiki.repository_url
    }
  }

  service_role = aws_iam_role.codebuild_role.arn
}