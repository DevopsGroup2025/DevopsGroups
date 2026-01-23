output "key_pair_name" {
  description = "Name of the AWS key pair"
  value       = aws_key_pair.ec2_key.key_name
}

output "key_pair_id" {
  description = "ID of the AWS key pair"
  value       = aws_key_pair.ec2_key.id
}

output "private_key_path" {
  description = "Path to the private key file"
  value       = local_file.private_key.filename
}

output "public_key_path" {
  description = "Path to the public key file"
  value       = local_file.public_key.filename
}

output "private_key_pem" {
  description = "Private key in PEM format"
  value       = tls_private_key.ssh_key.private_key_pem
  sensitive   = true
}

output "public_key_openssh" {
  description = "Public key in OpenSSH format"
  value       = tls_private_key.ssh_key.public_key_openssh
}
