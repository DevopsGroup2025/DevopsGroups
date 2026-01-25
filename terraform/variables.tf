variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for private subnets"
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Use a single NAT Gateway for all private subnets"
  type        = bool
  default     = true
}

variable "enable_vpc_flow_logs" {
  description = "Enable VPC Flow Logs"
  type        = bool
  default     = false
}

variable "vpc_azs_count" {
  description = "Number of availability zones for VPC"
  type        = number
  default     = 2
}
variable "key_pair_name" {
  description = "Name for the EC2 key pair"
  type        = string
  default     = "devops-team-key-pair"
}
variable "aws_region" {
  description = "AWS region to deploy resources into"
  type        = string
  default     = "eu-west-1"
}

variable "project_name" {
  description = "Project name used for tagging"
  type        = string
  default     = "terraform-ansible-webapp"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"]
}

variable "availability_zones" {
  description = "Availability zones"
  type        = list(string)
  default     = ["eu-west-1a", "eu-west-1b"]
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "db_username" {
  description = "Database username"
  type        = string
  default     = "dbadmin"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "managed_by" {
  description = "Name of the person or team managing the infrastructure"
  type        = string
  default     = "Abraham Ayamigah"
}

variable "ecr_backend_repo_name" {
  description = "Name for backend ECR repository"
  type        = string
  default     = "backend-app-repo"
}

variable "ecr_frontend_repo_name" {
  description = "Name for frontend ECR repository"
  type        = string
  default     = "frontend-app-repo"
}

variable "ecr_image_tag_mutability" {
  description = "Image tag mutability setting for ECR repositories"
  type        = string
  default     = "MUTABLE"
}

variable "ecr_scan_on_push" {
  description = "Enable image scanning on push for ECR repositories"
  type        = bool
  default     = true
}

# Additional variables from terraform.tfvars
variable "bastion_instance_type" {
  description = "Instance type for the bastion host"
  type        = string
  default     = "t3.micro"
}

variable "root_volume_size" {
  description = "Root EBS volume size in GB"
  type        = number
  default     = 8
}

variable "root_volume_type" {
  description = "Root EBS volume type"
  type        = string
  default     = "gp3"
}

variable "enable_ebs_encryption" {
  description = "Enable EBS volume encryption"
  type        = bool
  default     = true
}

variable "enable_detailed_monitoring" {
  description = "Enable detailed monitoring for EC2 instances"
  type        = bool
  default     = false
}

variable "ssh_cidr_blocks" {
  description = "Allowed CIDR blocks for SSH access"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "bastion_ssh_cidr_blocks" {
  description = "Allowed CIDR blocks for Bastion SSH access"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "http_cidr_blocks" {
  description = "Allowed CIDR blocks for HTTP access"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "https_cidr_blocks" {
  description = "Allowed CIDR blocks for HTTPS access"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "enable_https" {
  description = "Enable HTTPS access"
  type        = bool
  default     = false
}

variable "ssh_user" {
  description = "Default SSH user for EC2 instances"
  type        = string
  default     = "ec2-user"
}

variable "key_name_prefix" {
  description = "Prefix for SSH key names"
  type        = string
  default     = "devops-team-key"
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "notesdb"
}

variable "db_password" {
  description = "Database password"
  type        = string
  default     = "MySecurePassw0rd123!"
}

variable "db_instance_class" {
  description = "Database instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "Allocated storage for DB (GB)"
  type        = number
  default     = 20
}

variable "db_multi_az" {
  description = "Enable Multi-AZ for DB"
  type        = bool
  default     = false
}

variable "db_backup_retention_period" {
  description = "DB backup retention period (days)"
  type        = number
  default     = 7
}

variable "db_backup_window" {
  description = "Preferred DB backup window"
  type        = string
  default     = "03:00-04:00"
}

variable "db_maintenance_window" {
  description = "Preferred DB maintenance window"
  type        = string
  default     = "sun:04:00-sun:05:00"
}

variable "enable_rds_encryption" {
  description = "Enable RDS encryption"
  type        = bool
  default     = true
}

variable "enable_rds_monitoring" {
  description = "Enable RDS enhanced monitoring"
  type        = bool
  default     = false
}

variable "ecr_repository_names" {
  description = "List of ECR repository names"
  type        = list(string)
  default     = ["backend", "frontend", "proxy"]
}

variable "ecr_max_image_count" {
  description = "Max image count for ECR lifecycle policy"
  type        = number
  default     = 10
}

variable "enable_ssm_access" {
  description = "Enable SSM access for EC2 instances"
  type        = bool
  default     = true
}
