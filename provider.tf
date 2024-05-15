# Define provider
provider "aws" {
  region = var.aws_region
}

# Define Kubernetes provider
provider "kubernetes" {
  config_context_cluster = var.eks_cluster_name
}
