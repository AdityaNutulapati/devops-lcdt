# General Configuration

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-2"
}

variable "aws_profile" {
  description = "AWS CLI profile (leave empty to use default credential chain)"
  type        = string
  default     = ""
}

variable "project" {
  description = "Project name"
  type        = string
  default     = "lcdt"
}

variable "environment" {
  description = "Environment"
  type        = string
  default     = "production"
}

# Networking

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.20.0.0/16"
}

variable "azs" {
  description = "Availability zones to use"
  type        = list(string)
  default     = ["ap-south-2a", "ap-south-2b"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.20.0.0/24", "10.20.2.0/24"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.20.1.0/24", "10.20.3.0/24"]
}

# EKS Configuration

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "aditya-eks-cluster"
}

variable "cluster_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.36"
}

variable "node_instance_types" {
  description = "EC2 instance types"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_desired_size" {
  description = "Desired nodes"
  type        = number
  default     = 2
}

variable "node_min_size" {
  description = "Minimum nodes"
  type        = number
  default     = 2
}

variable "node_max_size" {
  description = "Maximum nodes"
  type        = number
  default     = 4
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "CIDR blocks allowed to access the EKS public API endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}
