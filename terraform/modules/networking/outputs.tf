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

# =============================================================================
# Full-stack Architecture Security Groups
# =============================================================================

# ALB/Bastion Security Group - Public facing
output "alb_security_group_id" {
  description = "ID of the ALB/Bastion security group (public facing)"
  value       = aws_security_group.alb.id
}

# Application Security Group - Private tier
output "application_security_group_id" {
  description = "ID of the application security group (private)"
  value       = aws_security_group.application.id
}

# Frontend Security Group (legacy)
output "frontend_security_group_id" {
  description = "ID of the frontend security group"
  value       = aws_security_group.frontend.id
}

# Backend Security Group (legacy)
output "backend_security_group_id" {
  description = "ID of the backend security group"
  value       = aws_security_group.backend.id
}

# Database Security Group
output "database_security_group_id" {
  description = "ID of the database security group"
  value       = aws_security_group.database.id
}
