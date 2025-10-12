terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Uncomment to use S3 backend for state management (recommended for production)
  # backend "s3" {
  #   bucket         = "your-terraform-state-bucket"
  #   key            = "medilink/terraform.tfstate"
  #   region         = "us-east-1"
  #   encrypt        = true
  #   dynamodb_table = "terraform-state-lock"
  # }
}

provider "aws" {
  region = var.aws_region

  # Use AWS credentials from environment variables or AWS CLI config
  # DO NOT hardcode credentials here!
  # Set these environment variables instead:
  # export AWS_ACCESS_KEY_ID="your-access-key"
  # export AWS_SECRET_ACCESS_KEY="your-secret-key"
  # OR use AWS CLI: aws configure

  default_tags {
    tags = {
      Project     = "MediLink"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}