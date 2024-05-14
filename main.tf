# Define provider
provider "aws" {
  region = "your_aws_region"
}

# Define Kubernetes provider
provider "kubernetes" {
  config_context_cluster = "your_eks_cluster_name"
}

# Create EKS cluster (use the appropriate module for Red Hat Linux nodes)
module "eks_cluster" {
  source            = "terraform-aws-modules/eks/aws"
  cluster_name      = "your_eks_cluster_name"
  cluster_version   = "1.20"
  subnets           = ["subnet-xxxxxx", "subnet-xxxxxx", "subnet-xxxxxx"] # Specify your subnet IDs
  vpc_id            = "your_vpc_id"
  node_groups       = {
    eks_nodes = {
      desired_capacity = 2
      max_capacity     = 10
      min_capacity     = 1
      instance_type    = "t2.medium"
      key_name         = "your_key_pair_name"
      # Add additional parameters for Red Hat Linux nodes
      ami_type         = "AL2_x86_64" # Red Hat Linux AMI type
      kubelet_extra_args = "--cloud-provider=aws" # Additional arguments for kubelet
    }
  }
}

# Configure kubeconfig
data "aws_eks_cluster" "eks_cluster" {
  name = module.eks_cluster.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks_cluster.cluster_id
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
  load_config_file       = false
}

# Deploy MediaWiki application
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
          image = "mediawiki:latest" # Use the appropriate MediaWiki image compatible with Red Hat Linux

          port {
            container_port = 80
          }
        }
      }
    }
  }
}

# Expose MediaWiki service
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

    type = "LoadBalancer" # Expose the service externally
  }
}
