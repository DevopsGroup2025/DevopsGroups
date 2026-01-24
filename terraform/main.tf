terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

module "vpc" {
  source             = "./modules/vpc"
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones
}

module "security" {
  source = "./modules/security"
  vpc_id = module.vpc.vpc_id
}

module "secrets" {
  source = "./modules/secrets"
}

module "iam" {
  source         = "./modules/iam"
  secret_arn     = module.database.db_secret_arn
}

module "compute" {
  source                     = "./modules/compute"
  vpc_id                     = module.vpc.vpc_id
  public_subnet_ids          = module.vpc.public_subnet_ids
  private_subnet_ids         = module.vpc.private_subnet_ids
  bastion_security_group_id  = module.security.bastion_security_group_id
  frontend_security_group_id = module.security.frontend_security_group_id
  backend_security_group_id  = module.security.backend_security_group_id
  iam_instance_profile_name  = module.iam.instance_profile_name
  instance_type              = var.instance_type
}

module "database" {
  source                = "./modules/database"
  private_subnet_ids    = module.vpc.private_subnet_ids
  db_security_group_id  = module.security.db_security_group_id
}
