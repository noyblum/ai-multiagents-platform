output "bedrock_agent_role_arn" {
  description = "ARN of the Bedrock agent IAM role"
  value       = aws_iam_role.bedrock_agent.arn
}

output "bedrock_agent_role_name" {
  description = "Name of the Bedrock agent IAM role"
  value       = aws_iam_role.bedrock_agent.name
}
