variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "bedrock_agent_role_arn" {
  description = "ARN of the IAM role for Bedrock agents"
  type        = string
}

variable "model_generic" {
  description = "Bedrock model for generic agent"
  type        = string
}

variable "model_coding" {
  description = "Bedrock model for coding agent"
  type        = string
}

variable "model_financial" {
  description = "Bedrock model for financial agent"
  type        = string
}

variable "model_supervisor" {
  description = "Bedrock model for supervisor agent"
  type        = string
}
