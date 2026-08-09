# General
aws_region  = "ap-south-2"
aws_profile = "lcdt"
project     = "lcdt"
environment = "production"

# Networking
vpc_cidr             = "10.20.0.0/16"
azs                  = ["ap-south-2a", "ap-south-2b"]
private_subnet_cidrs = ["10.20.0.0/24", "10.20.2.0/24"]
public_subnet_cidrs  = ["10.20.1.0/24", "10.20.3.0/24"]

# EKS
cluster_name        = "aditya-eks-cluster"
cluster_version     = "1.36"
node_instance_types = ["t3.micro"]
node_desired_size   = 3
node_min_size       = 3
node_max_size       = 3

cluster_endpoint_public_access_cidrs = ["0.0.0.0/0"]
