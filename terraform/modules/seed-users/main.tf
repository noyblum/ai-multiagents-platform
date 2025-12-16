# terraform/modules/seed-users/main.tf

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }
}

# Generate secure random passwords for each test user
resource "random_password" "test_user_noyblum" {
  length  = 16
  special = true
}

resource "random_password" "test_user_davidod" {
  length  = 16
  special = true
}

resource "random_password" "test_user_hanochblum" {
  length  = 16
  special = true
}

# Data source to get caller identity
data "aws_caller_identity" "current" {}

# Local variables
locals {
  test_users = [
    {
      email    = "noyblum@blumenfeld.com"
      name     = "Noy Blumenfeld"
      password = random_password.test_user_noyblum.result
    },
    {
      email    = "davidod@blumenfeld.com"
      name     = "David Od"
      password = random_password.test_user_davidod.result
    },
    {
      email    = "hanochblum@blumenfeld.com"
      name     = "Hanoch Blum"
      password = random_password.test_user_hanochblum.result
    }
  ]
}

# Use null_resource with a local-exec provisioner to seed users via Python script
resource "null_resource" "seed_users" {
  provisioner "local-exec" {
    command = "python3 ${path.module}/seed_users.py"
    environment = {
      DYNAMODB_TABLE = var.users_table_name
      AWS_REGION     = var.aws_region
      TEST_USERS_JSON = jsonencode(local.test_users)
    }
  }

  # Trigger update only when test users change
  triggers = {
    users_config = jsonencode(local.test_users)
  }
}
