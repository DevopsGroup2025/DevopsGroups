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

# Local variables for common tags
locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = var.managed_by
    CreatedAt   = timestamp()
  }
  
  availability_zones = slice(data.aws_availability_zones.available.names, 0, var.vpc_azs_count)
}

# Module: VPC
module "vpc" {
  source = "./modules/vpc"

  vpc_name             = "${var.project_name}-vpc"
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones   = local.availability_zones
  
  enable_dns_hostnames = true
  enable_dns_support   = true
  enable_nat_gateway   = var.enable_nat_gateway
  single_nat_gateway   = var.single_nat_gateway
  enable_flow_logs     = var.enable_vpc_flow_logs
  
  common_tags = local.common_tags
}

# Module: SSH Keys
module "keys" {
  source = "./modules/keys"

  key_pair_name        = var.key_name_prefix
  private_key_path     = "${path.module}/../ansible/keys/${var.project_name}-key.pem"
  key_algorithm        = "RSA"
  key_rsa_bits         = 4096
  private_key_permission = "0400"

  common_tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-key"
    }
  )
}

# Module: Networking (Security Group)
module "networking" {
  source = "./modules/networking"

  vpc_id                     = module.vpc.vpc_id
  security_group_name        = "${var.project_name}-sg"
  security_group_description = "Security group for ${var.project_name}"
  ssh_cidr_blocks            = var.ssh_cidr_blocks
  http_cidr_blocks           = var.http_cidr_blocks
  https_cidr_blocks          = var.https_cidr_blocks
  enable_https               = var.enable_https

  common_tags = local.common_tags
}

# Module: Compute (EC2 Instance)
module "compute" {
  source = "./modules/compute"

  subnet_id            = module.vpc.public_subnet_ids[0]
  instance_name        = "${var.project_name}-ec2"
  instance_type        = var.instance_type
  instance_role        = "web"
  environment          = "web_dev"
  key_pair_name        = module.keys.key_pair_name
  security_group_ids   = [module.networking.security_group_id]
  
  associate_public_ip  = true
  enable_monitoring    = var.enable_detailed_monitoring
  root_volume_size     = var.root_volume_size
  root_volume_type     = var.root_volume_type
  enable_encryption    = var.enable_ebs_encryption
  
  ssh_user             = var.ssh_user
  private_key_path     = module.keys.private_key_path
  inventory_file_path  = "${path.module}/../ansible/inventory.ini"

  common_tags = local.common_tags
}

# Module: Frontend Instance (Next.js)
module "frontend" {
  source = "./modules/compute"

  subnet_id            = module.vpc.public_subnet_ids[0]
  instance_name        = "${var.project_name}-frontend"
  instance_type        = var.instance_type
  instance_role        = "frontend"
  environment          = var.environment
  key_pair_name        = module.keys.key_pair_name
  security_group_ids   = [module.networking.frontend_security_group_id]
  
  associate_public_ip  = true
  enable_monitoring    = var.enable_detailed_monitoring
  root_volume_size     = var.root_volume_size
  root_volume_type     = var.root_volume_type
  enable_encryption    = var.enable_ebs_encryption
  
  ssh_user             = var.ssh_user
  private_key_path     = module.keys.private_key_path
  inventory_file_path  = "${path.module}/../ansible/inventory-frontend.ini"

  common_tags = local.common_tags
}

# Module: Backend Instance (NestJS)
module "backend" {
  source = "./modules/compute"

  subnet_id            = module.vpc.public_subnet_ids[1]
  instance_name        = "${var.project_name}-backend"
  instance_type        = var.instance_type
  instance_role        = "backend"
  environment          = var.environment
  key_pair_name        = module.keys.key_pair_name
  security_group_ids   = [module.networking.backend_security_group_id]
  
  associate_public_ip  = true
  enable_monitoring    = var.enable_detailed_monitoring
  root_volume_size     = var.root_volume_size
  root_volume_type     = var.root_volume_type
  enable_encryption    = var.enable_ebs_encryption
  
  ssh_user             = var.ssh_user
  private_key_path     = module.keys.private_key_path
  inventory_file_path  = "${path.module}/../ansible/inventory-backend.ini"

  common_tags = local.common_tags
}

# Module: RDS Database (PostgreSQL)
module "database" {
  source = "./modules/rds"

  db_identifier          = "${var.project_name}-db"
  db_name                = var.db_name
  master_username        = var.db_username
  master_password        = var.db_password
  instance_class         = var.db_instance_class
  allocated_storage      = var.db_allocated_storage
  
  subnet_ids             = module.vpc.private_subnet_ids
  security_group_ids     = [module.networking.database_security_group_id]
  
  multi_az               = var.db_multi_az
  backup_retention_period = var.db_backup_retention_period
  backup_window          = var.db_backup_window
  maintenance_window     = var.db_maintenance_window
  
  storage_encrypted      = var.enable_rds_encryption
  monitoring_interval    = var.enable_rds_monitoring ? 60 : 0
  
  common_tags = local.common_tags
}
