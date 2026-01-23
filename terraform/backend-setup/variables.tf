variable "aws_region" {
  description = "AWS region for backend resources"
  type        = string
  default     = "eu-west-1"
}

variable "project_name" {
  description = "Project name used for tagging"
  type        = string
  default     = "terraform-ansible-webapp"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "state_bucket_name" {
  description = "Name of the S3 bucket for Terraform state (must be globally unique)"
  type        = string
  # Update this with your unique bucket name
  default = "terraform-state-webapp-dev-12345"
}

variable "lock_table_name" {
  description = "Name of the DynamoDB table for state locking"
  type        = string
  default     = "terraform-state-lock-webapp"
}

variable "managed_by" {
  description = "Name of the person or team managing the infrastructure"
  type        = string
  default     = "Abraham Ayamigah"
}
