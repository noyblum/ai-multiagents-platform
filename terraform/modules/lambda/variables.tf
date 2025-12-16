# terraform/modules/lambda/variables.tf

variable "function_name" {
  description = "Name of the Lambda function"
  type        = string
}

variable "handler" {
  description = "Lambda function handler"
  type        = string
  default     = "lambda.handler"
}

variable "runtime" {
  description = "Lambda runtime"
  type        = string
  default     = "nodejs20.x"
}

variable "source_dir" {
  description = "Source directory containing Lambda code"
  type        = string
}

variable "timeout" {
  description = "Function timeout in seconds"
  type        = number
  default     = 30
}

variable "memory_size" {
  description = "Amount of memory in MB"
  type        = number
  default     = 512
}

variable "environment_variables" {
  description = "Environment variables for Lambda"
  type        = map(string)
  default     = {}
}

variable "bedrock_agent_arns" {
  description = "List of Bedrock agent ARNs to grant access to"
  type        = list(string)
  default     = []
}

variable "dynamodb_table_arns" {
  description = "List of DynamoDB table ARNs to grant access to"
  type        = list(string)
  default     = []
}

variable "layer_arns" {
  description = "List of Lambda layer ARNs to attach"
  type        = list(string)
  default     = []
}

variable "allow_self_invoke" {
  description = "Allow Lambda to invoke itself asynchronously"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
