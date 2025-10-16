##########################################
# Variables
##########################################
variable "vpc_cidr" {
  default = "192.168.0.0/16"
}

variable "private_subnets" {
  default = ["192.168.1.0/24", "192.168.2.0/24", "192.168.3.0/24"]
}

variable "public_subnets" {
  default = ["192.168.101.0/24", "192.168.102.0/24", "192.168.103.0/24"]
}

variable "region" {
  default = "us-east-1"
}

variable "key_name" {
  default = "your-key-pair" # optional, if you want SSH access
}

data "aws_availability_zones" "asz" {}

##########################################
# VPC Module
##########################################
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 4.0"

  name = "jenkins-vpc"
  cidr = var.vpc_cidr

  azs                  = data.aws_availability_zones.asz.names
  private_subnets      = var.private_subnets
  public_subnets       = var.public_subnets
  enable_dns_hostnames = true
  enable_nat_gateway   = true
  single_nat_gateway   = true

  tags = {
    "kubernetes.io/cluster/my-eks-cluster" = "shared"
  }

  public_subnet_tags = {
    "kubernetes.io/cluster/my-eks-cluster" = "shared"
    "kubernetes.io/role/elb"               = 1
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/my-eks-cluster" = "shared"
    "kubernetes.io/role/internal-elb"      = 1
  }
}

##########################################
# EKS Cluster Module
##########################################
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name               = "my-eks-cluster-3"
  kubernetes_version = "1.31"

  # Cluster endpoint access
  endpoint_public_access  = true
  endpoint_private_access = true

  # Networking
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets   # Nodes in private subnets

  # Managed Node Group
  eks_managed_node_groups = {
    nodes = {
      desired_size  = 2
      min_size      = 1
      max_size      = 3
      instance_type = ["t3.medium"]   # Enough memory for kubelet + pods
      key_name      = var.key_name
    }
  }

 

  tags = {
    Environment = "dev"
    Terraform   = "true"
  }


}

##########################################
# Outputs
##########################################
output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "cluster_security_group_id" {
  value = module.eks.cluster_security_group_id
}

output "node_group_role_arn" {
  value = module.eks.node_groups["nodes"].iam_role_arn
}

output "vpc_id" {
  value = module.vpc.vpc_id
}
