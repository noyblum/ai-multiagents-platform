variable "account_id" {
  description = "AWS Account ID - provided via tfvars file generated from environment variables"
  type        = string
  # Set via generate-tfvars.sh script or manually in env/*.tfvars
}

variable "project_name" {
  description = "Project name used for resource naming - provided via tfvars file"
  type        = string
  # Set via generate-tfvars.sh script or manually in env/*.tfvars
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "jwt_secret" {
  description = "Secret key for JWT token signing and verification"
  type        = string
  sensitive   = true
  default     = "your-secret-key-change-in-production"
}

variable "email_domain" {
  description = "Email domain for test user accounts"
  type        = string
  default     = "cross-river.com"
}

# Bedrock Model Configurations
variable "model_supervisor" {
  description = "Model ID for supervisor agent - using cross-region inference profile"
  type        = string
  default     = "us.anthropic.claude-3-5-sonnet-20241022-v2:0"  # Cross-region inference profile
}

variable "model_generic" {
  description = "Model ID for generic agent - using cross-region inference profile"
  type        = string
  default     = "us.anthropic.claude-3-5-sonnet-20241022-v2:0"  # Cross-region inference profile
}

variable "model_coding" {
  description = "Model ID for coding agent - using cross-region inference profile"
  type        = string
  default     = "us.anthropic.claude-3-5-sonnet-20241022-v2:0"  # Cross-region inference profile
}

variable "model_financial" {
  description = "Model ID for financial agent - using cross-region inference profile"
  type        = string
  default     = "us.anthropic.claude-3-5-sonnet-20241022-v2:0"  # Cross-region inference profile
}