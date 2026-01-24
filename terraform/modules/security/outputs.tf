output "alb_security_group_id" {
  value = aws_security_group.alb.id
}

output "bastion_security_group_id" {
  value = aws_security_group.bastion.id
}

output "frontend_security_group_id" {
  value = aws_security_group.frontend.id
}

output "backend_security_group_id" {
  value = aws_security_group.backend.id
}

output "db_security_group_id" {
  value = aws_security_group.database.id
}

output "key_pair_name" {
  value = aws_key_pair.bastion.key_name
}

output "bastion_key_path" {
  value = local_file.bastion_private_key.filename
}
