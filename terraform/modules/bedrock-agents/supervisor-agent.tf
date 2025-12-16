# Supervisor Agent (Router with Multi-Agent Collaboration)

resource "aws_bedrockagent_agent" "supervisor" {
  agent_name              = "${var.project_name}-supervisor-agent-${var.environment}"
  agent_resource_role_arn = var.bedrock_agent_role_arn
  foundation_model        = var.model_supervisor
  
  instruction = file("${path.module}/instructions/supervisor-agent.txt")
  
  idle_session_ttl_in_seconds = 600
  
  # Enable multi-agent collaboration
  agent_collaboration = "SUPERVISOR"
  
  # Do NOT prepare until collaborators are added
  prepare_agent = false
  
  tags = {
    Name        = "${var.project_name}-supervisor-agent"
    Environment = var.environment
    AgentType   = "supervisor"
  }
}

# Associate Collaborator Agents with Supervisor
# These must be created BEFORE setting agent_collaboration to SUPERVISOR
resource "aws_bedrockagent_agent_collaborator" "coding" {
  agent_id            = aws_bedrockagent_agent.supervisor.id
  agent_version       = "DRAFT"
  collaborator_name   = "coding-agent"
  collaboration_instruction = "Delegate ALL programming, software development, coding, debugging, technical implementation, AND mathematical calculations/computations to this agent. This includes simple math problems, complex calculations, algorithm questions, data structure problems, and any code-related tasks."
  
  relay_conversation_history = "TO_COLLABORATOR"
  
  # Don't prepare yet - let null_resource handle it
  prepare_agent = false
  
  agent_descriptor {
    alias_arn = aws_bedrockagent_agent_alias.coding.agent_alias_arn
  }

  # Ensure supervisor agent is created first
  depends_on = [aws_bedrockagent_agent.supervisor]
}

resource "aws_bedrockagent_agent_collaborator" "financial" {
  agent_id            = aws_bedrockagent_agent.supervisor.id
  agent_version       = "DRAFT"
  collaborator_name   = "financial-agent"
  collaboration_instruction = "Delegate ALL questions about money, investments, stocks, bonds, retirement, savings, budgeting, wealth, financial planning, portfolio management, and any investment advice to this agent. This includes questions about 'best stocks', 'where to invest', '401k', 'IRA', or any financial decisions."
  
  relay_conversation_history = "TO_COLLABORATOR"
  
  # Don't prepare yet - let null_resource handle it
  prepare_agent = false
  
  agent_descriptor {
    alias_arn = aws_bedrockagent_agent_alias.financial.agent_alias_arn
  }

  depends_on = [aws_bedrockagent_agent.supervisor]
}

resource "aws_bedrockagent_agent_collaborator" "generic" {
  agent_id            = aws_bedrockagent_agent.supervisor.id
  agent_version       = "DRAFT"
  collaborator_name   = "generic-agent"
  collaboration_instruction = "ONLY delegate general knowledge questions about history, geography, science facts, weather, news, movies, books, or casual conversation to this agent. DO NOT use for financial questions, programming questions, or mathematical calculations."
  
  relay_conversation_history = "TO_COLLABORATOR"
  
  # Don't prepare yet - let null_resource handle it
  prepare_agent = false
  
  agent_descriptor {
    alias_arn = aws_bedrockagent_agent_alias.generic.agent_alias_arn
  }

  depends_on = [aws_bedrockagent_agent.supervisor]
}# Supervisor Agent Alias - Prepares the agent WITH collaborators
resource "aws_bedrockagent_agent_alias" "supervisor" {
  agent_alias_name = "test"
  agent_id         = aws_bedrockagent_agent.supervisor.id
  description      = "Test alias for supervisor agent with multi-agent collaboration"
  
  # Ensure collaborators are associated before creating alias
  depends_on = [
    aws_bedrockagent_agent_collaborator.coding,
    aws_bedrockagent_agent_collaborator.financial,
    aws_bedrockagent_agent_collaborator.generic
  ]
}

# Prepare the supervisor agent after collaborators are added
resource "null_resource" "prepare_supervisor" {
  provisioner "local-exec" {
    command = <<-EOT
      aws bedrock-agent prepare-agent \
        --agent-id ${aws_bedrockagent_agent.supervisor.id} \
        --region ${data.aws_region.current.name}
    EOT
  }

  depends_on = [aws_bedrockagent_agent_alias.supervisor]
}