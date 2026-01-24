resource "tls_private_key" "main" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "main" {
  key_name   = "main-keypair"
  public_key = tls_private_key.main.public_key_openssh
}

resource "local_file" "private_key" {
  content  = tls_private_key.main.private_key_pem
  filename = "${path.module}/main-keypair.pem"
  file_permission = "0600"
}

resource "aws_ecr_repository" "frontend" {
  name = "frontend-app"
}

resource "aws_ecr_repository" "backend" {
  name = "backend-app"
}

resource "aws_lb" "main" {
  name               = "main-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_security_group_id]
  subnets            = var.public_subnet_ids
}

resource "aws_lb_target_group" "bastion" {
  name     = "bastion-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  health_check {
    path = "/"
  }
}

resource "aws_lb_listener" "main" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.bastion.arn
  }
}

resource "aws_instance" "bastion" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.main.key_name
  vpc_security_group_ids      = [var.bastion_security_group_id]
  subnet_id                   = var.public_subnet_ids[0]
  iam_instance_profile        = var.iam_instance_profile_name
  associate_public_ip_address = true
  
  tags = { Name = "bastion-nginx-proxy" }
}

resource "aws_instance" "frontend" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.main.key_name
  vpc_security_group_ids = [var.frontend_security_group_id]
  subnet_id              = var.private_subnet_ids[0]
  iam_instance_profile   = var.iam_instance_profile_name
  
  tags = { Name = "frontend" }
}

resource "aws_instance" "backend" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.main.key_name
  vpc_security_group_ids = [var.backend_security_group_id]
  subnet_id              = var.private_subnet_ids[1]
  iam_instance_profile   = var.iam_instance_profile_name
  
  tags = { Name = "backend" }
}

resource "aws_eip" "bastion" {
  domain = "vpc"
  tags   = { Name = "bastion-eip" }
}

resource "aws_eip_association" "bastion" {
  instance_id   = aws_instance.bastion.id
  allocation_id = aws_eip.bastion.id
}

resource "aws_lb_target_group_attachment" "bastion" {
  target_group_arn = aws_lb_target_group.bastion.arn
  target_id        = aws_instance.bastion.id
  port             = 80
}
