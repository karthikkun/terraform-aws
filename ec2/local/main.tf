# aws backend

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
  profile = "default"
}

resource "aws_s3_bucket" "remote-tf-state" {
  bucket        = "remote-tf-state"
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "remote-tf-state-bucket-versioning" {
  bucket = aws_s3_bucket.remote-tf-state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "remote-tf-state-bucket-encrypt-conf" {
  bucket        = aws_s3_bucket.remote-tf-state.bucket 
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_dynamodb_table" "tf_state_locks" {
  name         = "terraform-state-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"
  attribute {
    name = "LockID"
    type = "S"
  }
}