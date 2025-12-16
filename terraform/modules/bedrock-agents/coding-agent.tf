# Coding Agent
resource "aws_bedrockagent_agent" "coding" {
  agent_name              = "${var.project_name}-coding-agent-${var.environment}"
  agent_resource_role_arn = var.bedrock_agent_role_arn
  foundation_model        = var.model_coding
  
  instruction = file("${path.module}/instructions/coding-agent.txt")
  
  idle_session_ttl_in_seconds = 600
  
  tags = {
    Name        = "${var.project_name}-coding-agent"
    Environment = var.environment
    AgentType   = "coding"
  }
}

# Coding Agent Alias
resource "aws_bedrockagent_agent_alias" "coding" {
  agent_alias_name = "test-updated"
  agent_id         = aws_bedrockagent_agent.coding.id
  description      = "Updated alias for coding agent with Claude 3 Sonnet"
}
