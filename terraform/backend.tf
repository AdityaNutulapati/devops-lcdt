# S3 Remote Backend Configuration
# State stored in S3 with DynamoDB locking
#
# NOTE: Backend configuration cannot use variables or data sources.
# The bucket name includes the AWS account ID for uniqueness.
# Update the bucket name to match your AWS account ID.

terraform {
  backend "s3" {
    bucket         = "lcdt-terraform-state-515230700333"  # Update with your account ID
    key            = "eks/terraform.tfstate"
    region         = "ap-south-2"
    dynamodb_table = "lcdt-terraform-lock"
    encrypt        = true
    profile        = "lcdt"
  }
}
