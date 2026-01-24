# =============================================================================
# ECR Module Outputs
# =============================================================================

output "repository_urls" {
  description = "Map of repository names to their URLs"
  value       = { for k, v in aws_ecr_repository.main : k => v.repository_url }
}

output "repository_arns" {
  description = "Map of repository names to their ARNs"
  value       = { for k, v in aws_ecr_repository.main : k => v.arn }
}

output "repository_names" {
  description = "Map of repository keys to their full names"
  value       = { for k, v in aws_ecr_repository.main : k => v.name }
}

output "registry_id" {
  description = "The registry ID where the repositories are created"
  value       = length(aws_ecr_repository.main) > 0 ? values(aws_ecr_repository.main)[0].registry_id : null
}

output "registry_url" {
  description = "The ECR registry URL (without repository name)"
  value       = length(aws_ecr_repository.main) > 0 ? split("/", values(aws_ecr_repository.main)[0].repository_url)[0] : null
}

