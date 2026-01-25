

output "ecr_backend_repository_url" {
  description = "The URL of the backend ECR repository."
  value       = module.ecr_backend.repository_url
}

output "ecr_frontend_repository_url" {
  description = "The URL of the frontend ECR repository."
  value       = module.ecr_frontend.repository_url
}
output "bastion_public_ip" {
  description = "Public IP of bastion instance"
  value       = module.compute.bastion_public_ip
}

output "backend_public_ip" {
  description = "Public IP of first backend instance (for CI/CD)"
  value       = module.compute.bastion_public_ip
}

output "frontend_public_ip" {
  description = "Public IP of first frontend instance (for CI/CD)"
  value       = module.compute.bastion_public_ip
}

output "bastion_key_path" {
  description = "Path to bastion private key"
  value       = module.security.bastion_key_path
}

output "db_endpoint" {
  description = "PostgreSQL database endpoint"
  value       = module.database.db_endpoint
}

output "db_secret_arn" {
  description = "ARN of the database secret in Secrets Manager"
  value       = module.secrets.db_secret_arn
}

output "backend_ecr_repository_url" {
  description = "URL of the backend ECR repository"
  value       = module.ecr_backend.repository_url
}

output "frontend_ecr_repository_url" {
  description = "URL of the frontend ECR repository"
  value       = module.ecr_frontend.repository_url
}
