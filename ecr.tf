resource "aws_ecr_repository" "mediawiki" {
  name = var.ecr_repository_name
}