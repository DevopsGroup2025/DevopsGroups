output "region" {
  description = "AWS region used for deployment"
  value       = var.aws_region
}

# VPC Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = module.vpc.vpc_cidr
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = module.vpc.private_subnet_ids
}

# Key Outputs
output "key_name" {
  description = "EC2 key pair name"
  value       = module.keys.key_pair_name
}

output "private_key_path" {
  description = "Path to the private SSH key for Ansible"
  value       = module.keys.private_key_path
}

# Project Outputs
output "project_name" {
  description = "Project name used for tagging"
  value       = var.project_name
}

output "public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = module.compute.instance_public_ip
}

output "public_dns" {
  description = "Public DNS name of the EC2 instance"
  value       = module.compute.instance_public_dns
}

output "ssh_user" {
  description = "SSH username for Amazon Linux 2"
  value       = var.ssh_user
}

output "instance_id" {
  description = "ID of the EC2 instance"
  value       = module.compute.instance_id
}

output "security_group_id" {
  description = "ID of the security group"
  value       = module.networking.security_group_id
}

output "ssh_command" {
  description = "SSH command to connect to the instance"
  value       = "ssh -i ${module.keys.private_key_path} ${var.ssh_user}@${module.compute.instance_public_ip}"
}

output "web_url" {
  description = "URL to access the web application"
  value       = "http://${module.compute.instance_public_ip}"
}

# Frontend Outputs
output "frontend_public_ip" {
  description = "Public IP address of the frontend server"
  value       = module.frontend.instance_public_ip
}

output "frontend_instance_id" {
  description = "ID of the frontend EC2 instance"
  value       = module.frontend.instance_id
}

output "frontend_url" {
  description = "URL to access the Next.js frontend"
  value       = "http://${module.frontend.instance_public_ip}:3000"
}

# Backend Outputs
output "backend_public_ip" {
  description = "Public IP address of the backend server"
  value       = module.backend.instance_public_ip
}

output "backend_private_ip" {
  description = "Private IP address of the backend server"
  value       = module.backend.instance_private_ip
}

output "backend_instance_id" {
  description = "ID of the backend EC2 instance"
  value       = module.backend.instance_id
}

output "backend_api_url" {
  description = "URL to access the NestJS API"
  value       = "http://${module.backend.instance_public_ip}:3001"
}

# Database Outputs
output "database_endpoint" {
  description = "RDS instance endpoint"
  value       = module.database.db_instance_endpoint
  sensitive   = true
}

output "database_address" {
  description = "RDS instance address"
  value       = module.database.db_instance_address
}

output "database_port" {
  description = "RDS instance port"
  value       = module.database.db_instance_port
}

output "database_name" {
  description = "Name of the database"
  value       = module.database.db_name
}

output "database_connection_string" {
  description = "PostgreSQL connection string (without password)"
  value       = "postgresql://${module.database.db_username}@${module.database.db_instance_address}:${module.database.db_instance_port}/${module.database.db_name}"
  sensitive   = true
}
