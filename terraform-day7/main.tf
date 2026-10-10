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
      Owner        = "divya"
      CostCenter   = "cc-1001"
      BusinessUnit = "platform"
    }
  }
}

resource "aws_s3_bucket" "demo" {
  # checkov:skip=CKV_AWS_144:Cross-region replication not needed for a demo bucket
  # checkov:skip=CKV_AWS_18:Access logging not needed for a demo bucket
  # checkov:skip=CKV2_AWS_62:Event notifications not needed for a demo bucket
  # checkov:skip=CKV2_AWS_61:Lifecycle rules not needed for a demo bucket
  bucket = "devops-learner-day7-demo-67891"
}

# FIX 1: keep old versions of files
resource "aws_s3_bucket_versioning" "demo" {
  bucket = aws_s3_bucket.demo.id
  versioning_configuration {
    status = "Enabled"
  }
}

# FIX 2: block all public access
resource "aws_s3_bucket_public_access_block" "demo" {
  bucket                  = aws_s3_bucket.demo.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# FIX 3: encrypt with our own KMS key (now with a key policy)
data "aws_caller_identity" "current" {}

resource "aws_kms_key" "s3" {
  description         = "Key for the day7 demo bucket"
  enable_key_rotation = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowAccountAdmin"
        Effect    = "Allow"
        Principal = { AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root" }
        Action    = "kms:*"
        Resource  = "*"
      }
    ]
  })
}

resource "aws_s3_bucket_server_side_encryption_configuration" "demo" {
  bucket = aws_s3_bucket.demo.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.s3.arn
    }
  }
}