terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "ap-south-1"

  default_tags {
    tags = {
      Application  = "cloud-platform"
      Environment  = "dev"
      Owner        = "Divya"
      CostCenter   = "cc-1001"
      BusinessUnit = "platform"
    }
  }
}

resource "aws_s3_bucket" "demo" {
  bucket = "devops-learner-day7-demo-67891"
}