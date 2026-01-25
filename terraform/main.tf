terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

module "vpc" {
  source          = "./modules/vpc"
  vpc_cidr        = var.vpc_cidr
  public_subnets  = var.public_subnet_cidrs
  private_subnets = var.private_subnet_cidrs
  azs             = var.availability_zones
  project         = var.project_name
}

module "security" {
  source = "./modules/security"
  vpc_id = module.vpc.vpc_id
  project_name = var.project_name
}

module "secrets" {
  source      = "./modules/secrets"
  db_username = var.db_username
}

module "iam" {
  source     = "./modules/iam"
  secret_arn = module.secrets.db_secret_arn
  project_name = var.project_name
}

module "compute" {
  source                     = "./modules/compute"
  vpc_id                     = module.vpc.vpc_id
  public_subnet_ids          = module.vpc.public_subnet_ids
  private_subnet_ids         = module.vpc.private_subnet_ids
  bastion_security_group_id  = module.security.bastion_security_group_id
  frontend_security_group_id = module.security.frontend_security_group_id
  backend_security_group_id  = module.security.backend_security_group_id
  iam_instance_profile_name  = module.iam.ec2_instance_profile_name
  instance_type              = var.instance_type
  project_name               = var.project_name
  key_pair_name              = var.key_pair_name
}

module "database" {
  source                = "./modules/database"
  private_subnet_ids    = module.vpc.private_subnet_ids
  db_security_group_id  = module.security.db_security_group_id
  db_username           = module.secrets.db_username
  db_password           = module.secrets.db_password
  project_name          = var.project_name
}



module "ecr_backend" {
  source               = "./modules/ecr"
  name                 = var.ecr_backend_repo_name
  image_tag_mutability = var.ecr_image_tag_mutability
  scan_on_push         = var.ecr_scan_on_push
  tags = {
    Environment = var.environment
    Project     = var.project_name
    Component   = "backend"
    ManagedBy   = var.managed_by
  }
}

module "ecr_frontend" {
  source               = "./modules/ecr"
  name                 = var.ecr_frontend_repo_name
  image_tag_mutability = var.ecr_image_tag_mutability
  scan_on_push         = var.ecr_scan_on_push
  tags = {
    Environment = var.environment
    Project     = var.project_name
    Component   = "frontend"
    ManagedBy   = var.managed_by
  }
}
