# S3 Remote Backend Configuration
# State stored in S3 with DynamoDB locking

terraform {
  backend "s3" {
    bucket         = "lcdt-terraform-state-515230700333"
    key            = "eks/terraform.tfstate"
    region         = "ap-south-2"
    dynamodb_table = "lcdt-terraform-lock"
    encrypt        = true
    profile        = "lcdt"
  }
}
