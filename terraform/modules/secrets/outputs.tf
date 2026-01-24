output "db_secret_arn" {
  description = "ARN of the database secret"
  value       = aws_secretsmanager_secret.db_credentials.arn
}

output "db_secret_id" {
  description = "ID of the database secret"
  value       = aws_secretsmanager_secret.db_credentials.id
}

output "db_username" {
  description = "Database username"
  value       = var.db_username
}

output "db_password" {
  description = "Database password"
  value       = random_password.db_password.result
  sensitive   = true
}