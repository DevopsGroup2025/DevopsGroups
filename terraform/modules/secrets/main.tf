# Database secrets management with auto-generated password
resource "random_password" "db_password" {
  length  = 16
  special = true
}

resource "aws_secretsmanager_secret" "db_credentials" {
  name        = "database-credentials"
  description = "Database credentials for RDS instance"
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    username = var.db_username
    password = random_password.db_password.result
  })
}

# Data source to retrieve the generated secret
data "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
  depends_on = [aws_secretsmanager_secret_version.db_credentials]
}