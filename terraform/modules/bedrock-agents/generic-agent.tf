# Generic Agent
resource "aws_bedrockagent_agent" "generic" {
  agent_name              = "${var.project_name}-generic-agent-${var.environment}"
  agent_resource_role_arn = var.bedrock_agent_role_arn
  foundation_model        = var.model_generic
  
  instruction = file("${path.module}/instructions/generic-agent.txt")
  
  idle_session_ttl_in_seconds = 600
  
  tags = {
    Name        = "${var.project_name}-generic-agent"
    Environment = var.environment
    AgentType   = "generic"
  }
}

# Generic Agent Alias
resource "aws_bedrockagent_agent_alias" "generic" {
  agent_alias_name = "test"
  agent_id         = aws_bedrockagent_agent.generic.id
  description      = "Test alias for generic agent"
}
