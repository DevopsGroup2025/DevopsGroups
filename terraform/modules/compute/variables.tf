variable "vpc_id" {
  type = string
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "bastion_security_group_id" {
  type = string
}

variable "frontend_security_group_id" {
  type = string
}

variable "backend_security_group_id" {
  type = string
}

variable "iam_instance_profile_name" {
  type = string
}

variable "instance_type" {
  type = string
}

variable "frontend_instance_count" {
  description = "Number of frontend instances"
  type        = number
  default     = 2
}

variable "backend_instance_count" {
  description = "Number of backend instances"
  type        = number
  default     = 2
}

variable "key_pair_name" {
  description = "Name for the EC2 key pair"
  type        = string
  default     = "devops-team-key"
}

variable "cloudwatch_log_retention_days" {
  description = "CloudWatch log retention period in days"
  type        = number
  default     = 7
}

variable "project_name" {
  description = "Project name for tagging"
  type        = string
  default     = "terraform-ansible-webapp"
}
