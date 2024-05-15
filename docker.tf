resource "docker_image" "mediawiki" {
  name          = "${aws_ecr_repository.mediawiki.repository_url}:latest"
  build_context = "${path.module}/."
}

# Push the Docker image to ECR
resource "null_resource" "push_image_to_ecr" {
  triggers = {
    docker_image_id = docker_image.mediawiki.image_id
  }

  provisioner "local-exec" {
    command = "aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${aws_ecr_repository.mediawiki.repository_url} && docker push ${aws_ecr_repository.mediawiki.repository_url}:latest"
  }
}