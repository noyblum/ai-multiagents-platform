# terraform/lambdas.tf
# Individual Lambda functions for each route

################################################################################
# Login Lambda (JWT Authentication)
################################################################################

module "login_lambda" {
  source = "./modules/lambda"

  function_name = "${var.project_name}-login-${var.environment}"
  handler       = "index.handler"
  runtime       = "python3.12"
  source_dir    = "${path.module}/functions/login"
  timeout       = 10
  memory_size   = 128

  layer_arns = [module.auth_layer.layer_arn] # Use auth layer with bcrypt

  environment_variables = {
    NODE_ENV         = "production"
    JWT_SECRET       = var.jwt_secret
    EMAIL_DOMAIN     = var.email_domain
    USERS_TABLE_NAME = module.dynamodb.users_table_name
  }

  bedrock_agent_arns  = []                                # No Bedrock access needed
  dynamodb_table_arns = [module.dynamodb.users_table_arn] # Grant DynamoDB access

  tags = local.common_tags
}

################################################################################
# Health Check Lambda
################################################################################

module "health_lambda" {
  source = "./modules/lambda"

  function_name = "${var.project_name}-health-${var.environment}"
  handler       = "index.handler"
  runtime       = "python3.12"
  source_dir    = "${path.module}/functions/health"
  timeout       = 10
  memory_size   = 128

  environment_variables = {
    NODE_ENV = "production"
  }

  bedrock_agent_arns  = [] # No Bedrock access needed
  dynamodb_table_arns = [] # No DynamoDB access needed

  tags = local.common_tags
}

################################################################################
# Root Lambda (API Documentation)
################################################################################

module "root_lambda" {
  source = "./modules/lambda"

  function_name = "${var.project_name}-root-${var.environment}"
  handler       = "index.handler"
  runtime       = "python3.12"
  source_dir    = "${path.module}/functions/root"
  timeout       = 10
  memory_size   = 128

  environment_variables = {
    NODE_ENV = "production"
  }

  bedrock_agent_arns  = [] # No Bedrock access needed
  dynamodb_table_arns = [] # No DynamoDB access needed

  tags = local.common_tags
}

################################################################################
# List Agents Lambda
################################################################################

module "list_agents_lambda" {
  source = "./modules/lambda"

  function_name = "${var.project_name}-list-agents-${var.environment}"
  handler       = "index.handler"
  runtime       = "python3.12"
  source_dir    = "${path.module}/functions/list-agents"
  timeout       = 10
  memory_size   = 128

  layer_arns = [module.common_layer.layer_arn] # Use common layer

  environment_variables = {
    GENERIC_AGENT_ID          = module.bedrock_agents.generic_agent_id
    GENERIC_AGENT_ALIAS_ID    = module.bedrock_agents.generic_agent_alias_id
    CODING_AGENT_ID           = module.bedrock_agents.coding_agent_id
    CODING_AGENT_ALIAS_ID     = module.bedrock_agents.coding_agent_alias_id
    FINANCIAL_AGENT_ID        = module.bedrock_agents.financial_agent_id
    FINANCIAL_AGENT_ALIAS_ID  = module.bedrock_agents.financial_agent_alias_id
    SUPERVISOR_AGENT_ID       = module.bedrock_agents.supervisor_agent_id
    SUPERVISOR_AGENT_ALIAS_ID = module.bedrock_agents.supervisor_agent_alias_id
    NODE_ENV                  = "production"
    JWT_SECRET                = var.jwt_secret
  }

  bedrock_agent_arns  = [] # No Bedrock access needed for listing
  dynamodb_table_arns = [] # No DynamoDB access needed

  tags = local.common_tags
}


################################################################################
# Chat Lambda (Synchronous Bedrock invocation)
################################################################################

module "chat_lambda" {
  source = "./modules/lambda"

  function_name = "${var.project_name}-chat-${var.environment}"
  handler       = "index.handler"
  runtime       = "python3.12"
  source_dir    = "${path.module}/functions/chat"
  timeout       = 30  # Enough time for Bedrock agent response
  memory_size   = 512

  layer_arns = [module.common_layer.layer_arn]

  environment_variables = {
    SUPERVISOR_AGENT_ID       = module.bedrock_agents.supervisor_agent_id
    SUPERVISOR_AGENT_ALIAS_ID = module.bedrock_agents.supervisor_agent_alias_id
    CHAT_SESSIONS_TABLE_NAME  = module.dynamodb.chat_sessions_table_name
    NODE_ENV                  = "production"
    JWT_SECRET                = var.jwt_secret
  }

  bedrock_agent_arns = [
    module.bedrock_agents.generic_agent_arn,
    module.bedrock_agents.coding_agent_arn,
    module.bedrock_agents.financial_agent_arn,
    module.bedrock_agents.supervisor_agent_arn
  ]
  dynamodb_table_arns = [module.dynamodb.chat_sessions_table_arn]

  tags = local.common_tags
}

################################################################################
# Chat Status Lambda (for polling async chat results)
################################################################################

module "chat_status_lambda" {
  source = "./modules/lambda"

  function_name = "${var.project_name}-chat-status-${var.environment}"
  handler       = "index.handler"
  runtime       = "python3.12"
  source_dir    = "${path.module}/functions/chat-status"
  timeout       = 10
  memory_size   = 128

  layer_arns = [module.common_layer.layer_arn] # Use common layer

  environment_variables = {
    CHAT_SESSIONS_TABLE_NAME = module.dynamodb.chat_sessions_table_name
    NODE_ENV                 = "production"
    JWT_SECRET               = var.jwt_secret
  }

  bedrock_agent_arns  = [] # No Bedrock access needed
  dynamodb_table_arns = [module.dynamodb.chat_sessions_table_arn]

  tags = local.common_tags
}

