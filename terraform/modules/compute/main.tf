# Compute Module - EC2 Instance

data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

resource "aws_instance" "web_server" {
  ami           = var.custom_ami != "" ? var.custom_ami : data.aws_ami.amazon_linux_2.id
  instance_type = var.instance_type
  key_name      = var.key_pair_name
  subnet_id     = var.subnet_id

  vpc_security_group_ids = var.security_group_ids
  
  monitoring              = var.enable_monitoring
  associate_public_ip_address = var.associate_public_ip

  root_block_device {
    volume_size           = var.root_volume_size
    volume_type           = var.root_volume_type
    delete_on_termination = true
    encrypted             = var.enable_encryption
  }

  user_data = var.user_data

  tags = merge(
    var.common_tags,
    {
      Name        = var.instance_name
      Role        = var.instance_role
      Environment = var.environment
    }
  )
}

# Create Ansible inventory file
resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/templates/inventory.tpl", {
    public_ip        = aws_instance.web_server.public_ip
    ssh_user         = var.ssh_user
    private_key_path = var.private_key_path
    instance_name    = var.instance_name
  })
  filename = var.inventory_file_path
}
