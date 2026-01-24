# =============================================================================
# IAM Module Outputs
# =============================================================================

output "ec2_role_arn" {
  description = "ARN of the EC2 IAM role"
  value       = aws_iam_role.ec2_role.arn
}

output "ec2_role_name" {
  description = "Name of the EC2 IAM role"
  value       = aws_iam_role.ec2_role.name
}

output "ec2_instance_profile_name" {
  description = "Name of the EC2 instance profile"
  value       = aws_iam_instance_profile.ec2_profile.name
}

output "ec2_instance_profile_arn" {
  description = "ARN of the EC2 instance profile"
  value       = aws_iam_instance_profile.ec2_profile.arn
}

output "bastion_role_arn" {
  description = "ARN of the bastion IAM role"
  value       = var.create_bastion_role ? aws_iam_role.bastion_role[0].arn : null
}

output "bastion_instance_profile_name" {
  description = "Name of the bastion instance profile"
  value       = var.create_bastion_role ? aws_iam_instance_profile.bastion_profile[0].name : null
}
