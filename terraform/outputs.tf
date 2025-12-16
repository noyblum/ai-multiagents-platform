# terraform/outputs-serverless.tf
# Outputs for serverless architecture

# Lambda Functions
output "health_lambda_name" {
  description = "Health check Lambda function name"
  value       = module.health_lambda.function_name
}

output "list_agents_lambda_name" {
  description = "List agents Lambda function name"
  value       = module.list_agents_lambda.function_name
}

output "chat_lambda_name" {
  description = "Chat Lambda function name"
  value       = module.chat_lambda.function_name
}

# Frontend
output "frontend_url" {
  description = "CloudFront URL for frontend"
  value       = module.frontend.website_url
}

output "frontend_bucket" {
  description = "S3 bucket name for frontend"
  value       = module.frontend.bucket_name
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID"
  value       = module.frontend.cloudfront_distribution_id
}

# Bedrock Agents
output "generic_agent_id" {
  description = "ID of the generic agent"
  value       = module.bedrock_agents.generic_agent_id
}

output "generic_agent_alias_id" {
  description = "Alias ID of the generic agent"
  value       = module.bedrock_agents.generic_agent_alias_id
}

output "coding_agent_id" {
  description = "ID of the coding agent"
  value       = module.bedrock_agents.coding_agent_id
}

output "coding_agent_alias_id" {
  description = "Alias ID of the coding agent"
  value       = module.bedrock_agents.coding_agent_alias_id
}

output "financial_agent_id" {
  description = "ID of the financial agent"
  value       = module.bedrock_agents.financial_agent_id
}

output "financial_agent_alias_id" {
  description = "Alias ID of the financial agent"
  value       = module.bedrock_agents.financial_agent_alias_id
}

output "supervisor_agent_id" {
  description = "ID of the supervisor agent"
  value       = module.bedrock_agents.supervisor_agent_id
}

output "supervisor_agent_alias_id" {
  description = "Alias ID of the supervisor agent"
  value       = module.bedrock_agents.supervisor_agent_alias_id
}

# DynamoDB
output "users_table_name" {
  description = "Name of the users DynamoDB table"
  value       = module.dynamodb.users_table_name
}

output "sessions_table_name" {
  description = "Name of the sessions DynamoDB table"
  value       = module.dynamodb.sessions_table_name
}
