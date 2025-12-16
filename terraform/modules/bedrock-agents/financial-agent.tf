# Financial Advisor Agent
resource "aws_bedrockagent_agent" "financial" {
  agent_name              = "${var.project_name}-financial-agent-${var.environment}"
  agent_resource_role_arn = var.bedrock_agent_role_arn
  foundation_model        = var.model_financial
  
  instruction = file("${path.module}/instructions/financial-agent.txt")
  
  idle_session_ttl_in_seconds = 600
  
  tags = {
    Name        = "${var.project_name}-financial-agent"
    Environment = var.environment
    AgentType   = "financial"
  }
}

# Financial Agent Alias
resource "aws_bedrockagent_agent_alias" "financial" {
  agent_alias_name = "test"
  agent_id         = aws_bedrockagent_agent.financial.id
  description      = "Test alias for financial agent"
}
