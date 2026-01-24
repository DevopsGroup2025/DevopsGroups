# =============================================================================
# Terraform Outputs
# =============================================================================

output "region" {
  description = "AWS region used for deployment"
  value       = var.aws_region
}

# =============================================================================
# VPC Outputs
# =============================================================================
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

# =============================================================================
# Key Outputs
# =============================================================================
output "key_name" {
  description = "EC2 key pair name"
  value       = module.keys.key_pair_name
}

output "private_key_path" {
  description = "Path to the private SSH key for Ansible"
  value       = module.keys.private_key_path
}

# =============================================================================
# Project Outputs
# =============================================================================
output "project_name" {
  description = "Project name used for tagging"
  value       = var.project_name
}

output "ssh_user" {
  description = "SSH username for Amazon Linux 2"
  value       = var.ssh_user
}

# =============================================================================
# Bastion Host Outputs (Public - Entry Point)
# =============================================================================
output "bastion_public_ip" {
  description = "Public IP address of the bastion/load balancer host"
  value       = module.bastion.instance_public_ip
}

output "bastion_public_dns" {
  description = "Public DNS name of the bastion host"
  value       = module.bastion.instance_public_dns
}

output "bastion_instance_id" {
  description = "ID of the bastion EC2 instance"
  value       = module.bastion.instance_id
}

output "ssh_command_bastion" {
  description = "SSH command to connect to the bastion host"
  value       = "ssh -i ${module.keys.private_key_path} ${var.ssh_user}@${module.bastion.instance_public_ip}"
}

output "web_url" {
  description = "URL to access the web application (via bastion/load balancer)"
  value       = "http://${module.bastion.instance_public_ip}"
}

# =============================================================================
# Frontend Outputs (Private Subnet)
# =============================================================================
output "frontend_private_ip" {
  description = "Private IP address of the frontend server"
  value       = module.frontend.instance_private_ip
}

output "frontend_instance_id" {
  description = "ID of the frontend EC2 instance"
  value       = module.frontend.instance_id
}

output "ssh_command_frontend" {
  description = "SSH command to connect to frontend (via bastion)"
  value       = "ssh -i ${module.keys.private_key_path} -J ${var.ssh_user}@${module.bastion.instance_public_ip} ${var.ssh_user}@${module.frontend.instance_private_ip}"
}

# =============================================================================
# Backend Outputs (Private Subnet)
# =============================================================================
output "backend_private_ip" {
  description = "Private IP address of the backend server"
  value       = module.backend.instance_private_ip
}

output "backend_instance_id" {
  description = "ID of the backend EC2 instance"
  value       = module.backend.instance_id
}

output "ssh_command_backend" {
  description = "SSH command to connect to backend (via bastion)"
  value       = "ssh -i ${module.keys.private_key_path} -J ${var.ssh_user}@${module.bastion.instance_public_ip} ${var.ssh_user}@${module.backend.instance_private_ip}"
}

# =============================================================================
# Database Outputs
# =============================================================================
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

# =============================================================================
# ECR Outputs
# =============================================================================
output "ecr_registry_url" {
  description = "ECR registry URL (use for docker login)"
  value       = module.ecr.registry_url
}

output "ecr_repository_urls" {
  description = "Map of ECR repository URLs for each service"
  value       = module.ecr.repository_urls
}

output "ecr_repository_names" {
  description = "Map of ECR repository names"
  value       = module.ecr.repository_names
}

# =============================================================================
# IAM Outputs
# =============================================================================
output "ec2_instance_profile_name" {
  description = "Name of the EC2 instance profile"
  value       = module.iam.ec2_instance_profile_name
}

# =============================================================================
# Security Group Outputs
# =============================================================================
output "alb_security_group_id" {
  description = "ID of the ALB/Bastion security group"
  value       = module.networking.alb_security_group_id
}

output "application_security_group_id" {
  description = "ID of the application security group"
  value       = module.networking.application_security_group_id
}

output "database_security_group_id" {
  description = "ID of the database security group"
  value       = module.networking.database_security_group_id
}

# =============================================================================
# Ansible Inventory Helpers
# =============================================================================
output "ansible_inventory" {
  description = "Ansible inventory content for all hosts"
  value       = <<-EOT
    [bastion]
    ${module.bastion.instance_public_ip} ansible_user=${var.ssh_user}
    
    [frontend]
    ${module.frontend.instance_private_ip} ansible_user=${var.ssh_user}
    
    [backend]
    ${module.backend.instance_private_ip} ansible_user=${var.ssh_user}
    
    [app:children]
    frontend
    backend
    
    [all:vars]
    ansible_ssh_private_key_file=${module.keys.private_key_path}
    ansible_ssh_common_args='-o ProxyJump=${var.ssh_user}@${module.bastion.instance_public_ip}'
    db_host=${module.database.db_instance_address}
    db_port=${module.database.db_instance_port}
    db_name=${module.database.db_name}
    ecr_registry=${module.ecr.registry_url}
  EOT
}
