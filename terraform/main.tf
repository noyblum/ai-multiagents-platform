# terraform/main-serverless.tf
# Serverless architecture using Lambda + API Gateway + S3/CloudFront
terraform {
  required_version = ">= 1.5.0"
  backend "s3" {
    bucket = "tf-345757498837-ai-agents-platform-dev"
    key    = "ai-agents-platform/dev/terraform.tfstate"
    region = "us-east-1"
    encrypt = true
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}

locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    AccountId   = var.account_id
  }
}



################################################################################
# Frontend (S3 + CloudFront)
################################################################################

module "frontend" {
  source = "./modules/s3-cloudfront"

  project_name     = var.project_name
  environment      = var.environment
  existing_oac_id  = "E2CX0OTFFGBU1K"  # Existing OAC created manually

  tags = local.common_tags
}

# Generate frontend config.js from template
resource "local_file" "frontend_config" {
  content = templatefile("${path.module}/config.js.tpl", {
    api_url      = "${aws_apigatewayv2_api.main.api_endpoint}/prod"
    email_domain = var.email_domain
  })
  filename = "${path.module}/../frontend/config.js"
}

################################################################################
# Bedrock Agents
################################################################################

module "bedrock_agents" {
  source = "./modules/bedrock-agents"

  project_name           = var.project_name
  environment            = var.environment
  bedrock_agent_role_arn = module.iam.bedrock_agent_role_arn
  model_generic          = var.model_generic
  model_coding           = var.model_coding
  model_financial        = var.model_financial
  model_supervisor       = var.model_supervisor
}

module "iam" {
  source = "./modules/iam"

  project_name = var.project_name
  environment  = var.environment
}

################################################################################
# DynamoDB
################################################################################

module "dynamodb" {
  source = "./modules/dynamodb"

  project_name = var.project_name
  environment  = var.environment
}
