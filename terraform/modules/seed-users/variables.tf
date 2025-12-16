# terraform/modules/seed-users/variables.tf

variable "users_table_name" {
  description = "Name of the DynamoDB users table"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}
