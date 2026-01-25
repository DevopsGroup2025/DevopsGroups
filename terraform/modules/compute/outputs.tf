output "bastion_public_ip" {
  description = "Public IP of the bastion/load balancer instance"
  value       = aws_eip.bastion.public_ip
}

output "frontend_instance_ids" {
  description = "IDs of frontend instances"
  value       = aws_instance.frontend[*].id
}

output "backend_instance_ids" {
  description = "IDs of backend instances"
  value       = aws_instance.backend[*].id
}

output "frontend_private_ips" {
  description = "Private IPs of frontend instances"
  value       = aws_instance.frontend[*].private_ip
}

output "backend_private_ips" {
  description = "Private IPs of backend instances"
  value       = aws_instance.backend[*].private_ip
}

output "private_key_path" {
  description = "Path to the private key file"
  value       = local_file.private_key.filename
}
