# SSH Key Management Module

resource "tls_private_key" "ssh_key" {
  algorithm = var.key_algorithm
  rsa_bits  = var.key_rsa_bits
}

resource "local_file" "private_key" {
  content         = tls_private_key.ssh_key.private_key_pem
  filename        = var.private_key_path
  file_permission = var.private_key_permission
}

resource "local_file" "public_key" {
  content         = tls_private_key.ssh_key.public_key_openssh
  filename        = "${var.private_key_path}.pub"
  file_permission = "0644"
}

resource "aws_key_pair" "ec2_key" {
  key_name   = var.key_pair_name
  public_key = tls_private_key.ssh_key.public_key_openssh

  tags = var.common_tags
}
