# terraform/modules/lambda/main.tf

locals {
  common_tags = merge(
    var.tags,
    {
      ManagedBy = "Terraform"
    }
  )
}

# Archive Lambda code (Python only)
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = var.source_dir
  output_path = "${path.module}/../../../.terraform/lambda-${var.function_name}.zip"
  
  excludes = [
    "node_modules",
    "node_modules/**",
    "__pycache__",
    "__pycache__/**",
    "*.pyc",
    ".env",
    "*.md",
    ".git",
    "package.json",
    "package-lock.json",
    "function.zip"
  ]
}

# IAM role for Lambda
resource "aws_iam_role" "lambda" {
  name = "${var.function_name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })

  tags = local.common_tags
}

# Basic Lambda execution policy
resource "aws_iam_role_policy_attachment" "lambda_basic" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaRole"
  role       = aws_iam_role.lambda.name
}

# Bedrock access policy
resource "aws_iam_role_policy" "bedrock_access" {
  count = length(var.bedrock_agent_arns) > 0 ? 1 : 0
  
  name = "${var.function_name}-bedrock-policy"
  role = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "bedrock:InvokeAgent"
        ]
        # Allow access to both agents and their aliases
        Resource = [
          "arn:aws:bedrock:*:*:agent/*",
          "arn:aws:bedrock:*:*:agent-alias/*/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "bedrock:InvokeModel",
          "bedrock:InvokeModelWithResponseStream"
        ]
        Resource = [
          "arn:aws:bedrock:*::foundation-model/*",
          "arn:aws:bedrock:*:*:inference-profile/*"
        ]
      }
    ]
  })
}

# DynamoDB access policy
resource "aws_iam_role_policy" "dynamodb_access" {
  count = length(var.dynamodb_table_arns) > 0 ? 1 : 0
  
  name = "${var.function_name}-dynamodb-policy"
  role = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ]
        Resource = concat(
          var.dynamodb_table_arns,
          [for arn in var.dynamodb_table_arns : "${arn}/index/*"]
        )
      }
    ]
  })
}

# Self-invoke policy (for async background processing)
resource "aws_iam_role_policy" "self_invoke" {
  count = var.allow_self_invoke ? 1 : 0
  
  name = "${var.function_name}-self-invoke-policy"
  role = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "lambda:InvokeFunction"
        ]
        Resource = aws_lambda_function.this.arn
      }
    ]
  })
}

# Lambda function
resource "aws_lambda_function" "this" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = var.function_name
  role            = aws_iam_role.lambda.arn
  handler         = var.handler
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  runtime         = var.runtime
  timeout         = var.timeout
  memory_size     = var.memory_size
  layers          = var.layer_arns

  environment {
    variables = merge(
      var.environment_variables,
      {
        NODE_ENV = "production"
      }
    )
  }

  tags = local.common_tags
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${var.function_name}"
  retention_in_days = 7

  tags = local.common_tags
}
