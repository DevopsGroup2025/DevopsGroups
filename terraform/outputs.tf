output "bastion_public_ip" {
  description = "Public IP of bastion instance"
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
  value       = module.database.db_secret_arn
}
