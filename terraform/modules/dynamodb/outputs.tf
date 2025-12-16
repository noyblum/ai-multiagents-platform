output "users_table_name" {
  description = "Name of the users table"
  value       = aws_dynamodb_table.users.name
}

output "users_table_arn" {
  description = "ARN of the users table"
  value       = aws_dynamodb_table.users.arn
}

output "sessions_table_name" {
  description = "Name of the sessions table"
  value       = aws_dynamodb_table.sessions.name
}

output "sessions_table_arn" {
  description = "ARN of the sessions table"
  value       = aws_dynamodb_table.sessions.arn
}

output "chat_sessions_table_name" {
  description = "Name of the chat sessions table"
  value       = aws_dynamodb_table.chat_sessions.name
}

output "chat_sessions_table_arn" {
  description = "ARN of the chat sessions table"
  value       = aws_dynamodb_table.chat_sessions.arn
}
