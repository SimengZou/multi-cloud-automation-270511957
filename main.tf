# Fetch the current AWS account ID (used for ECR URLs and IAM)
data "aws_caller_identity" "current" {}

# Define standardized tags and names to keep the code clean
locals {
  common_tags = {
    Project     = var.project_name
    Environment = "Production"
    ManagedBy   = "Terraform"
    Owner       = "Simeng-Zou"
  }
}

