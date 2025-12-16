# IAM Role for Bedrock Agents

resource "aws_iam_role" "bedrock_agent" {
  name = "${var.project_name}-bedrock-agent-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "bedrock.amazonaws.com"
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
          ArnLike = {
            "aws:SourceArn" = "arn:aws:bedrock:${var.aws_region}:${data.aws_caller_identity.current.account_id}:agent/*"
          }
        }
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-bedrock-agent-role"
    Environment = var.environment
  }
}

# Policy for Bedrock model invocation
resource "aws_iam_role_policy" "bedrock_model_invocation" {
  name = "${var.project_name}-bedrock-model-policy-${var.environment}"
  role = aws_iam_role.bedrock_agent.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "bedrock:InvokeModel",
          "bedrock:InvokeModelWithResponseStream"
        ]
        Resource = [
          "arn:aws:bedrock:*::foundation-model/*",
          "arn:aws:bedrock:*:*:inference-profile/*"  # Cross-region inference profiles
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "bedrock:InvokeAgent",
          "bedrock:GetAgent",
          "bedrock:GetAgentAlias"
        ]
        Resource = [
          "arn:aws:bedrock:${var.aws_region}:${data.aws_caller_identity.current.account_id}:agent/*",
          "arn:aws:bedrock:${var.aws_region}:${data.aws_caller_identity.current.account_id}:agent-alias/*"
        ]
      }
    ]
  })
}

# Data source for AWS account ID
data "aws_caller_identity" "current" {}
