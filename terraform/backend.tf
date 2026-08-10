# S3 Remote Backend Configuration
# State stored in S3 with DynamoDB locking
#
# NOTE: Backend configuration uses partial configuration.
# The bucket name (which includes AWS account ID) is specified in backend.hcl
# This keeps sensitive/account-specific values out of version control.
#
# Usage:
#   terraform init -backend-config=backend.hcl

terraform {
  backend "s3" {
    key            = "eks/terraform.tfstate"
    region         = "ap-south-2"
    dynamodb_table = "lcdt-terraform-lock"
    encrypt        = true
  }
}
