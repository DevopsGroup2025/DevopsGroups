resource "tls_private_key" "main" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "main" {
  key_name   = var.key_pair_name
  public_key = tls_private_key.main.public_key_openssh
}

resource "local_file" "private_key" {
  content         = tls_private_key.main.private_key_pem
  filename        = "${path.module}/${var.key_pair_name}.pem"
  file_permission = "0600"
}

# CloudWatch Log Groups
resource "aws_cloudwatch_log_group" "frontend_logs" {
  name              = "/aws/ec2/${var.project_name}/frontend"
  retention_in_days = var.cloudwatch_log_retention_days
}

resource "aws_cloudwatch_log_group" "backend_logs" {
  name              = "/aws/ec2/${var.project_name}/backend"
  retention_in_days = var.cloudwatch_log_retention_days
}

resource "aws_cloudwatch_log_group" "docker_logs" {
  name              = "/aws/ec2/${var.project_name}/docker"
  retention_in_days = var.cloudwatch_log_retention_days
}



resource "aws_instance" "load_balancer" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.main.key_name
  vpc_security_group_ids      = [var.bastion_security_group_id]
  subnet_id                   = var.public_subnet_ids[0]
  iam_instance_profile        = var.iam_instance_profile_name
  associate_public_ip_address = true
  
  tags = { 
    Name    = "${var.project_name}-load-balancer"
    Project = var.project_name
    Role    = "load_balancer"
  }
}

resource "aws_instance" "frontend" {
  count                  = var.frontend_instance_count
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.main.key_name
  vpc_security_group_ids = [var.frontend_security_group_id]
  subnet_id              = var.private_subnet_ids[count.index % length(var.private_subnet_ids)]
  iam_instance_profile   = var.iam_instance_profile_name
  
  user_data = file("${path.module}/user_data/frontend.sh")
  
  tags = {
    Name    = "${var.project_name}-frontend-${count.index + 1}"
    Project = var.project_name
    Role    = "frontend"
  }
}

resource "aws_instance" "backend" {
  count                  = var.backend_instance_count
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.main.key_name
  vpc_security_group_ids = [var.backend_security_group_id]
  subnet_id              = var.private_subnet_ids[count.index % length(var.private_subnet_ids)]
  iam_instance_profile   = var.iam_instance_profile_name
  
  user_data = file("${path.module}/user_data/backend.sh")
  
  tags = { 
    Name    = "${var.project_name}-backend-${count.index + 1}"
    Project = var.project_name
    Role    = "backend"
  }
}

resource "aws_eip" "bastion" {
  domain = "vpc"
  tags = { 
    Name    = "${var.project_name}-load-balancer-eip"
    Project = var.project_name
    Role    = "load_balancer"
  }
}

resource "aws_eip_association" "bastion" {
  instance_id   = aws_instance.load_balancer.id
  allocation_id = aws_eip.bastion.id
}


