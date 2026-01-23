output "security_group_id" {
  description = "ID of the security group"
  value       = aws_security_group.web_sg.id
}

output "security_group_name" {
  description = "Name of the security group"
  value       = aws_security_group.web_sg.name
}

output "security_group_arn" {
  description = "ARN of the security group"
  value       = aws_security_group.web_sg.arn
}

# Full-stack security groups
output "frontend_security_group_id" {
  description = "ID of the frontend security group"
  value       = aws_security_group.frontend.id
}

output "backend_security_group_id" {
  description = "ID of the backend security group"
  value       = aws_security_group.backend.id
}

output "database_security_group_id" {
  description = "ID of the database security group"
  value       = aws_security_group.database.id
}
