# =============================================================================
# Terraform Configuration - Multi-Tier AWS Infrastructure
# =============================================================================
# Architecture:
#   Internet -> ALB/Bastion (public) -> App Servers (private) -> RDS (private)
#
# Components:
#   - VPC with public and private subnets across 2 AZs
#   - NAT Gateway for private subnet internet access
#   - Bastion host with Nginx for load balancing and SSH jump
#   - Frontend and Backend EC2 instances in private subnets
#   - RDS PostgreSQL in private subnets
#   - ECR repositories for Docker images
#   - IAM roles for EC2 to access ECR
# =============================================================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Data source for availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

# Data source for current AWS account
data "aws_caller_identity" "current" {}

# Local variables for common tags
locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = var.managed_by
  }

  availability_zones = slice(data.aws_availability_zones.available.names, 0, var.vpc_azs_count)

  # ECR registry URL
  ecr_registry_url = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com"
}

# =============================================================================
# Module: VPC
# =============================================================================
module "vpc" {
  source = "./modules/vpc"

  vpc_name             = "${var.project_name}-vpc"
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones   = local.availability_zones

  enable_dns_hostnames = true
  enable_dns_support   = true
  enable_nat_gateway   = var.enable_nat_gateway # Must be true for private instances
  single_nat_gateway   = var.single_nat_gateway
  enable_flow_logs     = var.enable_vpc_flow_logs

  common_tags = local.common_tags
}

# =============================================================================
# Module: ECR - Container Registry for Docker Images
# =============================================================================
module "ecr" {
  source = "./modules/ecr"

  project_name     = var.project_name
  repository_names = var.ecr_repository_names

  image_tag_mutability       = "MUTABLE"
  scan_on_push               = true
  max_image_count            = var.ecr_max_image_count
  untagged_image_expiry_days = 7
  force_delete               = true

  common_tags = local.common_tags
}

# =============================================================================
# Module: IAM - Instance Profiles for EC2
# =============================================================================
module "iam" {
  source = "./modules/iam"

  project_name           = var.project_name
  enable_ecr_access      = true
  enable_ssm_access      = var.enable_ssm_access
  enable_cloudwatch_logs = true
  create_bastion_role    = true

  common_tags = local.common_tags
}

# Module: SSH Keys
module "keys" {
  source = "./modules/keys"

  key_pair_name          = var.key_name_prefix
  private_key_path       = "${path.module}/../ansible/keys/${var.project_name}-key.pem"
  key_algorithm          = "RSA"
  key_rsa_bits           = 4096
  private_key_permission = "0400"

  common_tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-key"
    }
  )
}

# =============================================================================
# Module: Networking (Security Groups)
# =============================================================================
module "networking" {
  source = "./modules/networking"

  vpc_id                     = module.vpc.vpc_id
  vpc_cidr                   = var.vpc_cidr
  security_group_name        = "${var.project_name}-sg"
  security_group_description = "Security group for ${var.project_name}"
  ssh_cidr_blocks            = var.ssh_cidr_blocks
  bastion_ssh_cidr_blocks    = var.bastion_ssh_cidr_blocks
  http_cidr_blocks           = var.http_cidr_blocks
  https_cidr_blocks          = var.https_cidr_blocks
  enable_https               = var.enable_https

  common_tags = local.common_tags
}

# =============================================================================
# Module: Bastion Host (Public Subnet - Load Balancer + Jump Box)
# =============================================================================
# The bastion host serves two purposes:
#   1. Nginx reverse proxy/load balancer for incoming traffic
#   2. SSH jump box to access private instances
# =============================================================================
module "bastion" {
  source = "./modules/compute"

  subnet_id            = module.vpc.public_subnet_ids[0]
  instance_name        = "${var.project_name}-bastion"
  instance_type        = var.bastion_instance_type
  instance_role        = "bastion"
  environment          = var.environment
  key_pair_name        = module.keys.key_pair_name
  security_group_ids   = [module.networking.alb_security_group_id]
  iam_instance_profile = module.iam.bastion_instance_profile_name

  associate_public_ip = true # Must be public for incoming traffic
  enable_monitoring   = var.enable_detailed_monitoring
  root_volume_size    = var.root_volume_size
  root_volume_type    = var.root_volume_type
  enable_encryption   = var.enable_ebs_encryption

  ssh_user            = var.ssh_user
  private_key_path    = module.keys.private_key_path
  inventory_file_path = "${path.module}/../ansible/inventory-bastion.ini"

  common_tags = local.common_tags
}

# =============================================================================
# Module: Frontend Instances (Private Subnets - Next.js) - Multi-AZ
# =============================================================================
# Create frontend instances in each private subnet for high availability
# =============================================================================
module "frontend" {
  source = "./modules/compute"

  for_each = {
    for idx, subnet_id in module.vpc.private_subnet_ids : idx => {
      subnet_id = subnet_id
      az_suffix = local.availability_zones[idx]
    }
  }

  subnet_id            = each.value.subnet_id
  instance_name        = "${var.project_name}-frontend-${each.value.az_suffix}"
  instance_type        = var.instance_type
  instance_role        = "frontend"
  environment          = var.environment
  key_pair_name        = module.keys.key_pair_name
  security_group_ids   = [module.networking.application_security_group_id]
  iam_instance_profile = module.iam.ec2_instance_profile_name

  associate_public_ip = false # No public IP - accessed via bastion
  enable_monitoring   = var.enable_detailed_monitoring
  root_volume_size    = var.root_volume_size
  root_volume_type    = var.root_volume_type
  enable_encryption   = var.enable_ebs_encryption

  ssh_user            = var.ssh_user
  private_key_path    = module.keys.private_key_path
  inventory_file_path = "${path.module}/../ansible/inventory-frontend-${each.key}.ini"

  common_tags = local.common_tags

  depends_on = [module.vpc] # Ensure NAT Gateway is ready
}

# =============================================================================
# Module: Backend Instances (Private Subnets - NestJS) - Multi-AZ
# =============================================================================
# Create backend instances in each private subnet for high availability
# =============================================================================
module "backend" {
  source = "./modules/compute"

  for_each = {
    for idx, subnet_id in module.vpc.private_subnet_ids : idx => {
      subnet_id = subnet_id
      az_suffix = local.availability_zones[idx]
    }
  }

  subnet_id            = each.value.subnet_id
  instance_name        = "${var.project_name}-backend-${each.value.az_suffix}"
  instance_type        = var.instance_type
  instance_role        = "backend"
  environment          = var.environment
  key_pair_name        = module.keys.key_pair_name
  security_group_ids   = [module.networking.application_security_group_id]
  iam_instance_profile = module.iam.ec2_instance_profile_name

  associate_public_ip = false # No public IP - accessed via bastion
  enable_monitoring   = var.enable_detailed_monitoring
  root_volume_size    = var.root_volume_size
  root_volume_type    = var.root_volume_type
  enable_encryption   = var.enable_ebs_encryption

  ssh_user            = var.ssh_user
  private_key_path    = module.keys.private_key_path
  inventory_file_path = "${path.module}/../ansible/inventory-backend-${each.key}.ini"

  common_tags = local.common_tags

  depends_on = [module.vpc] # Ensure NAT Gateway is ready
}

# Module: RDS Database (PostgreSQL)
module "database" {
  source = "./modules/rds"

  db_identifier     = "${var.project_name}-db"
  db_name           = var.db_name
  master_username   = var.db_username
  master_password   = var.db_password
  instance_class    = var.db_instance_class
  allocated_storage = var.db_allocated_storage

  subnet_ids         = module.vpc.private_subnet_ids
  security_group_ids = [module.networking.database_security_group_id]

  multi_az                = var.db_multi_az
  backup_retention_period = var.db_backup_retention_period
  backup_window           = var.db_backup_window
  maintenance_window      = var.db_maintenance_window

  storage_encrypted   = var.enable_rds_encryption
  monitoring_interval = var.enable_rds_monitoring ? 60 : 0

  common_tags = local.common_tags
}

# =============================================================================
# Ansible Inventory File - Auto-generated after Terraform Apply
# =============================================================================
# Creates a unified inventory file with all hosts configured for SSH via bastion
# =============================================================================
resource "local_file" "ansible_inventory_unified" {
  content = <<-EOT
    # =============================================================================
    # Ansible Inventory - Auto-generated by Terraform
    # =============================================================================
    # Architecture: Bastion (public) -> App Servers (private) -> RDS (private)
    # =============================================================================

    # -----------------------------------------------------------------------------
    # Bastion Host (Public - SSH Jump Host + Load Balancer)
    # -----------------------------------------------------------------------------
    [bastion]
    ${module.bastion.instance_public_ip} ansible_user=${var.ssh_user}

    [bastion:vars]
    ansible_ssh_private_key_file=${abspath(module.keys.private_key_path)}
    ansible_ssh_common_args=-o StrictHostKeyChecking=no
    ansible_python_interpreter=/usr/bin/python3
    instance_role=bastion

    # -----------------------------------------------------------------------------
    # Frontend Servers (Private - Next.js) - Multi-AZ
    # -----------------------------------------------------------------------------
    [frontend]
%{ for key, frontend in module.frontend ~}
    ${frontend.instance_private_ip} ansible_user=${var.ssh_user}
%{ endfor ~}

    [frontend:vars]
    ansible_ssh_private_key_file=${abspath(module.keys.private_key_path)}
    ansible_ssh_common_args=-o StrictHostKeyChecking=no -o ProxyJump=${var.ssh_user}@${module.bastion.instance_public_ip}
    ansible_python_interpreter=/usr/bin/python3
    instance_role=frontend

    # -----------------------------------------------------------------------------
    # Backend Servers (Private - NestJS) - Multi-AZ
    # -----------------------------------------------------------------------------
    [backend]
%{ for key, backend in module.backend ~}
    ${backend.instance_private_ip} ansible_user=${var.ssh_user}
%{ endfor ~}

    [backend:vars]
    ansible_ssh_private_key_file=${abspath(module.keys.private_key_path)}
    ansible_ssh_common_args=-o StrictHostKeyChecking=no -o ProxyJump=${var.ssh_user}@${module.bastion.instance_public_ip}
    ansible_python_interpreter=/usr/bin/python3
    instance_role=backend

    # -----------------------------------------------------------------------------
    # Application Servers Group (Frontend + Backend)
    # -----------------------------------------------------------------------------
    [app:children]
    frontend
    backend

    # -----------------------------------------------------------------------------
    # All Servers Group
    # -----------------------------------------------------------------------------
    [all:children]
    bastion
    app

    # -----------------------------------------------------------------------------
    # Global Variables
    # -----------------------------------------------------------------------------
    [all:vars]
    # Database Configuration
    db_host=${module.database.db_instance_address}
    db_port=${module.database.db_instance_port}
    db_name=${module.database.db_name}
    db_username=${module.database.db_username}

    # ECR Configuration
    ecr_registry=${local.ecr_registry_url}
    ecr_backend_repo=${module.ecr.repository_urls["backend"]}
    ecr_frontend_repo=${module.ecr.repository_urls["frontend"]}
    ecr_proxy_repo=${module.ecr.repository_urls["proxy"]}
    aws_region=${var.aws_region}

    # Instance IPs (for internal communication)
    bastion_public_ip=${module.bastion.instance_public_ip}
    # Frontend IPs (comma-separated for Nginx upstream)
    frontend_private_ips=${join(",", [for f in module.frontend : f.instance_private_ip])}
    # Backend IPs (comma-separated for Nginx upstream)
    backend_private_ips=${join(",", [for b in module.backend : b.instance_private_ip])}
  EOT

  filename = "${path.module}/../ansible/inventory/hosts.ini"

  depends_on = [module.bastion, module.frontend, module.backend, module.database, module.ecr]
}
