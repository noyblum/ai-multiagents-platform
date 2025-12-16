# Secrets Manager for JWT Token
resource "aws_secretsmanager_secret" "jwt_secret" {
  name        = "${var.project_name}-jwt-secret-${var.environment}"
  description = "JWT secret for token signing and verification"

  tags = local.common_tags
}

resource "aws_secretsmanager_secret_version" "jwt_secret" {
  secret_id     = aws_secretsmanager_secret.jwt_secret.id
  secret_string = var.jwt_secret
}

# Grant Lambda functions access to read the secret
resource "aws_iam_policy" "secrets_read" {
  name        = "${var.project_name}-secrets-read-${var.environment}"
  description = "Allow Lambda functions to read JWT secret from Secrets Manager"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = aws_secretsmanager_secret.jwt_secret.arn
      }
    ]
  })
}
