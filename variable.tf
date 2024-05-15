variable "region" {
  description = "The AWS region to deploy resources in."
  type        = string
  default     = "us-west-2"
}

variable "cluster_name" {
  description = "The name of the EKS cluster."
  type        = string
  default     = "my-eks-cluster"
}

variable "cluster_version" {
  description = "The Kubernetes version for the EKS cluster."
  type        = string
  default     = "1.21"
}

variable "vpc_id" {
  description = "The ID of the VPC where the EKS cluster will be deployed."
  type        = string
}

variable "subnet_ids" {
  description = "A list of subnet IDs where the EKS cluster will be deployed."
  type        = list(string)
}

variable "instance_type" {
  description = "The EC2 instance type for the worker nodes."
  type        = string
  default     = "t3.medium"
}

variable "desired_capacity" {
  description = "The desired number of worker nodes."
  type        = number
  default     = 2
}

variable "max_capacity" {
  description = "The maximum number of worker nodes."
  type        = number
  default     = 4
}

variable "min_capacity" {
  description = "The minimum number of worker nodes."
  type        = number
  default     = 1
}

variable "ecr_repository_name" {
  description = "Name of the ECR repository."
  type        = string
  default     = "mediawiki"
}

variable "github_repository_owner" {
  description = "The owner of the GitHub repository."
  type        = string
}

variable "github_repository_name" {
  description = "The name of the GitHub repository."
  type        = string
}

variable "github_branch" {
  description = "The branch of the GitHub repository."
  type        = string
}
