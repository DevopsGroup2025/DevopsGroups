# Security Groups for Full-Stack Architecture

# Frontend Security Group (Next.js)
resource "aws_security_group" "frontend" {
  name        = "${var.security_group_name}-frontend"
  description = "Security group for Next.js frontend server"
  vpc_id      = var.vpc_id

  tags = merge(
    var.common_tags,
    {
      Name = "${var.security_group_name}-frontend"
      Tier = "frontend"
    }
  )
}

# Frontend Rules
resource "aws_security_group_rule" "frontend_ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = var.ssh_cidr_blocks
  security_group_id = aws_security_group.frontend.id
  description       = "SSH access"
}

resource "aws_security_group_rule" "frontend_http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.frontend.id
  description       = "HTTP access"
}

resource "aws_security_group_rule" "frontend_https" {
  count             = var.enable_https ? 1 : 0
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.frontend.id
  description       = "HTTPS access"
}

resource "aws_security_group_rule" "frontend_nextjs" {
  type              = "ingress"
  from_port         = 3000
  to_port           = 3000
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.frontend.id
  description       = "Next.js application"
}

resource "aws_security_group_rule" "frontend_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.frontend.id
  description       = "All outbound traffic"
}

# Backend Security Group (NestJS)
resource "aws_security_group" "backend" {
  name        = "${var.security_group_name}-backend"
  description = "Security group for NestJS backend API server"
  vpc_id      = var.vpc_id

  tags = merge(
    var.common_tags,
    {
      Name = "${var.security_group_name}-backend"
      Tier = "backend"
    }
  )
}

# Backend Rules
resource "aws_security_group_rule" "backend_ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = var.ssh_cidr_blocks
  security_group_id = aws_security_group.backend.id
  description       = "SSH access"
}

resource "aws_security_group_rule" "backend_http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.backend.id
  description       = "HTTP access for nginx reverse proxy"
}

resource "aws_security_group_rule" "backend_api_from_frontend" {
  type                     = "ingress"
  from_port                = 3001
  to_port                  = 3001
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.frontend.id
  security_group_id        = aws_security_group.backend.id
  description              = "API access from frontend"
}

resource "aws_security_group_rule" "backend_api_direct" {
  type              = "ingress"
  from_port         = 3001
  to_port           = 3001
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.backend.id
  description       = "Direct API access (for testing)"
}

resource "aws_security_group_rule" "backend_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.backend.id
  description       = "All outbound traffic"
}

# Database Security Group (RDS)
resource "aws_security_group" "database" {
  name        = "${var.security_group_name}-database"
  description = "Security group for RDS PostgreSQL database"
  vpc_id      = var.vpc_id

  tags = merge(
    var.common_tags,
    {
      Name = "${var.security_group_name}-database"
      Tier = "database"
    }
  )
}

# Database Rules
resource "aws_security_group_rule" "database_from_backend" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.backend.id
  security_group_id        = aws_security_group.database.id
  description              = "PostgreSQL access from backend"
}

resource "aws_security_group_rule" "database_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.database.id
  description       = "All outbound traffic"
}
