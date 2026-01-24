# =============================================================================
# ECR Module Variables
# =============================================================================

variable "project_name" {
  description = "Project name used as prefix for ECR repository names"
  type        = string
}

variable "repository_names" {
  description = "List of repository names to create (e.g., ['backend', 'frontend', 'proxy'])"
  type        = list(string)
}

variable "image_tag_mutability" {
  description = "Tag mutability setting for the repository (MUTABLE or IMMUTABLE)"
  type        = string
  default     = "MUTABLE"

  validation {
    condition     = contains(["MUTABLE", "IMMUTABLE"], var.image_tag_mutability)
    error_message = "Image tag mutability must be either MUTABLE or IMMUTABLE."
  }
}

variable "scan_on_push" {
  description = "Enable image scanning on push for vulnerability detection"
  type        = bool
  default     = true
}

variable "encryption_type" {
  description = "Encryption type for the repository (AES256 or KMS)"
  type        = string
  default     = "AES256"

  validation {
    condition     = contains(["AES256", "KMS"], var.encryption_type)
    error_message = "Encryption type must be either AES256 or KMS."
  }
}

variable "kms_key_arn" {
  description = "ARN of KMS key for encryption (required if encryption_type is KMS)"
  type        = string
  default     = null
}

variable "max_image_count" {
  description = "Maximum number of images to keep per repository"
  type        = number
  default     = 10
}

variable "untagged_image_expiry_days" {
  description = "Number of days after which untagged images expire"
  type        = number
  default     = 7
}

variable "enable_cross_account_access" {
  description = "Enable cross-account access to ECR repositories"
  type        = bool
  default     = false
}

variable "cross_account_arns" {
  description = "List of AWS account ARNs allowed to pull images"
  type        = list(string)
  default     = []
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
