<<<<<<< HEAD
variable "secret_arn" {
  type = string
=======
# =============================================================================
# IAM Module Variables
# =============================================================================

variable "project_name" {
  description = "Project name used as prefix for IAM resource names"
  type        = string
}

variable "enable_ecr_access" {
  description = "Enable ECR read access for pulling Docker images"
  type        = bool
  default     = true
}

variable "enable_ssm_access" {
  description = "Enable SSM access for secure shell access without SSH keys"
  type        = bool
  default     = true
}

variable "enable_cloudwatch_logs" {
  description = "Enable CloudWatch Logs access for container logging"
  type        = bool
  default     = true
}

variable "enable_secrets_manager" {
  description = "Enable Secrets Manager access for retrieving secrets"
  type        = bool
  default     = false
}

variable "secrets_arns" {
  description = "List of Secrets Manager ARNs the EC2 instances can access"
  type        = list(string)
  default     = ["*"]
}

variable "create_bastion_role" {
  description = "Create a separate role for bastion host"
  type        = bool
  default     = true
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
>>>>>>> 75f3543 (full clear workflow)
}
