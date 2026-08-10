################################################################################
# Provider Configuration
################################################################################

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile != "" ? var.aws_profile : null

  default_tags {
    tags = local.common_tags
  }
}

################################################################################
# Data Sources
################################################################################

data "aws_caller_identity" "current" {}

################################################################################
# Local Values
################################################################################

locals {
  account_id = data.aws_caller_identity.current.account_id
  
  common_tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

################################################################################
# Networking Module
# Creates VPC, IGW, public/private subnets, NAT Gateway, route tables
################################################################################

module "networking" {
  source = "./modules/networking"

  vpc_cidr             = var.vpc_cidr
  azs                  = var.azs
  private_subnet_cidrs = var.private_subnet_cidrs
  public_subnet_cidrs  = var.public_subnet_cidrs
  cluster_name         = var.cluster_name
  tags                 = local.common_tags
}

################################################################################
# IAM Module
# Creates IAM roles for EKS cluster and node groups
################################################################################

module "iam" {
  source = "./modules/iam"

  cluster_name = var.cluster_name
  tags         = local.common_tags
}

################################################################################
# EKS Module
# Creates EKS cluster, node group, OIDC provider, and add-ons
################################################################################

module "eks" {
  source = "./modules/eks"

  cluster_name                         = var.cluster_name
  cluster_version                      = var.cluster_version
  vpc_id                               = module.networking.vpc_id
  private_subnet_ids                   = module.networking.private_subnet_ids
  cluster_role_arn                     = module.iam.cluster_role_arn
  node_role_arn                        = module.iam.node_role_arn
  node_instance_types                  = var.node_instance_types
  node_desired_size                    = var.node_desired_size
  node_min_size                        = var.node_min_size
  node_max_size                        = var.node_max_size
  cluster_endpoint_public_access_cidrs = var.cluster_endpoint_public_access_cidrs
  tags                                 = local.common_tags

  depends_on = [module.networking, module.iam]
}
