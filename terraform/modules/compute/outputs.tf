output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.web_server.id
}

output "instance_public_ip" {
  description = "Public IP address of the instance"
  value       = aws_instance.web_server.public_ip
}

output "instance_public_dns" {
  description = "Public DNS name of the instance"
  value       = aws_instance.web_server.public_dns
}

output "instance_private_ip" {
  description = "Private IP address of the instance"
  value       = aws_instance.web_server.private_ip
}

output "instance_arn" {
  description = "ARN of the EC2 instance"
  value       = aws_instance.web_server.arn
}

output "ami_id" {
  description = "AMI ID used for the instance"
  value       = aws_instance.web_server.ami
}
