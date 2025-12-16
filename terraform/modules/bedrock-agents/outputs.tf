output "generic_agent_id" {
  description = "ID of the generic agent"
  value       = aws_bedrockagent_agent.generic.id
}

output "generic_agent_arn" {
  description = "ARN of the generic agent"
  value       = aws_bedrockagent_agent.generic.agent_arn
}

output "generic_agent_alias_id" {
  description = "Alias ID of the generic agent"
  value       = aws_bedrockagent_agent_alias.generic.agent_alias_id
}

output "coding_agent_id" {
  description = "ID of the coding agent"
  value       = aws_bedrockagent_agent.coding.id
}

output "coding_agent_arn" {
  description = "ARN of the coding agent"
  value       = aws_bedrockagent_agent.coding.agent_arn
}

output "coding_agent_alias_id" {
  description = "Alias ID of the coding agent"
  value       = aws_bedrockagent_agent_alias.coding.agent_alias_id
}

output "financial_agent_id" {
  description = "ID of the financial agent"
  value       = aws_bedrockagent_agent.financial.id
}

output "financial_agent_arn" {
  description = "ARN of the financial agent"
  value       = aws_bedrockagent_agent.financial.agent_arn
}

output "financial_agent_alias_id" {
  description = "Alias ID of the financial agent"
  value       = aws_bedrockagent_agent_alias.financial.agent_alias_id
}

output "supervisor_agent_id" {
  description = "ID of the supervisor agent"
  value       = aws_bedrockagent_agent.supervisor.id
}

output "supervisor_agent_arn" {
  description = "ARN of the supervisor agent"
  value       = aws_bedrockagent_agent.supervisor.agent_arn
}

output "supervisor_agent_alias_id" {
  description = "Alias ID of the supervisor agent"
  value       = aws_bedrockagent_agent_alias.supervisor.agent_alias_id
}
