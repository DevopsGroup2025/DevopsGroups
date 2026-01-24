# =============================================================================
# Security Groups for Full-Stack Architecture
# =============================================================================
# Architecture:
#   Internet -> ALB/Bastion (public) -> App Servers (private) -> Database (private)
#
# Security Groups:
#   - ALB/Bastion: Accepts HTTP/HTTPS/SSH from internet
#   - Application: Accepts traffic only from ALB/Bastion
#   - Database: Accepts traffic only from Application servers
# =============================================================================

# -----------------------------------------------------------------------------
# ALB/Bastion Security Group - Public facing (Load Balancer + Jump Box)
# -----------------------------------------------------------------------------
resource "aws_security_group" "alb" {
  name        = "${var.security_group_name}-alb"
  description = "Security group for ALB/Bastion host - public facing"
  vpc_id      = var.vpc_id

  tags = merge(
    var.common_tags,
    {
      Name = "${var.security_group_name}-alb"
      Tier = "public"
    }
  )
}

# ALB Rules - Accept HTTP from internet
resource "aws_security_group_rule" "alb_http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = var.http_cidr_blocks
  security_group_id = aws_security_group.alb.id
  description       = "HTTP from internet"
}

# ALB Rules - Accept HTTPS from internet
resource "aws_security_group_rule" "alb_https" {
  count             = var.enable_https ? 1 : 0
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = var.https_cidr_blocks
  security_group_id = aws_security_group.alb.id
  description       = "HTTPS from internet"
}

# ALB/Bastion Rules - Accept SSH for bastion access
resource "aws_security_group_rule" "alb_ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = var.bastion_ssh_cidr_blocks
  security_group_id = aws_security_group.alb.id
  description       = "SSH access to bastion"
}

# ALB Rules - All outbound
resource "aws_security_group_rule" "alb_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb.id
  description       = "All outbound traffic"
}

# -----------------------------------------------------------------------------
# Application Security Group - Private (Frontend + Backend servers)
# -----------------------------------------------------------------------------
resource "aws_security_group" "application" {
  name        = "${var.security_group_name}-application"
  description = "Security group for application servers (frontend + backend)"
  vpc_id      = var.vpc_id

  tags = merge(
    var.common_tags,
    {
      Name = "${var.security_group_name}-application"
      Tier = "application"
    }
  )
}

# Application Rules - SSH only from bastion
resource "aws_security_group_rule" "app_ssh_from_bastion" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb.id
  security_group_id        = aws_security_group.application.id
  description              = "SSH from bastion host only"
}

# Application Rules - HTTP from ALB only
resource "aws_security_group_rule" "app_http_from_alb" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb.id
  security_group_id        = aws_security_group.application.id
  description              = "HTTP from ALB only"
}

# Application Rules - Frontend port from ALB
resource "aws_security_group_rule" "app_frontend_from_alb" {
  type                     = "ingress"
  from_port                = 3000
  to_port                  = 3000
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb.id
  security_group_id        = aws_security_group.application.id
  description              = "Frontend (Next.js) from ALB"
}

# Application Rules - Backend port from ALB and within app tier
resource "aws_security_group_rule" "app_backend_from_alb" {
  type                     = "ingress"
  from_port                = 3001
  to_port                  = 3001
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb.id
  security_group_id        = aws_security_group.application.id
  description              = "Backend (NestJS) from ALB"
}

# Application Rules - Backend communication within app tier
resource "aws_security_group_rule" "app_backend_internal" {
  type                     = "ingress"
  from_port                = 3001
  to_port                  = 3001
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.application.id
  security_group_id        = aws_security_group.application.id
  description              = "Backend internal communication"
}

# Application Rules - All outbound (for NAT gateway access to ECR, etc.)
resource "aws_security_group_rule" "app_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.application.id
  description       = "All outbound traffic"
}

# -----------------------------------------------------------------------------
# Frontend Security Group (Legacy - kept for backward compatibility)
# -----------------------------------------------------------------------------
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

# Frontend Rules - SSH from bastion only
resource "aws_security_group_rule" "frontend_ssh" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb.id
  security_group_id        = aws_security_group.frontend.id
  description              = "SSH from bastion"
}

# Frontend Rules - HTTP from ALB
resource "aws_security_group_rule" "frontend_http" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb.id
  security_group_id        = aws_security_group.frontend.id
  description              = "HTTP from ALB"
}

# Frontend Rules - Next.js port from ALB
resource "aws_security_group_rule" "frontend_nextjs" {
  type                     = "ingress"
  from_port                = 3000
  to_port                  = 3000
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb.id
  security_group_id        = aws_security_group.frontend.id
  description              = "Next.js from ALB"
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

# -----------------------------------------------------------------------------
# Backend Security Group (Legacy - kept for backward compatibility)
# -----------------------------------------------------------------------------
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

# Backend Rules - SSH from bastion only
resource "aws_security_group_rule" "backend_ssh" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb.id
  security_group_id        = aws_security_group.backend.id
  description              = "SSH from bastion"
}

# Backend Rules - HTTP from ALB
resource "aws_security_group_rule" "backend_http" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb.id
  security_group_id        = aws_security_group.backend.id
  description              = "HTTP from ALB"
}

# Backend Rules - API from ALB
resource "aws_security_group_rule" "backend_api_from_alb" {
  type                     = "ingress"
  from_port                = 3001
  to_port                  = 3001
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb.id
  security_group_id        = aws_security_group.backend.id
  description              = "API access from ALB"
}

# Backend Rules - API from frontend
resource "aws_security_group_rule" "backend_api_from_frontend" {
  type                     = "ingress"
  from_port                = 3001
  to_port                  = 3001
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.frontend.id
  security_group_id        = aws_security_group.backend.id
  description              = "API access from frontend"
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

# Database Rules - Allow from application security group (used by frontend/backend instances)
resource "aws_security_group_rule" "database_from_application" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.application.id
  security_group_id        = aws_security_group.database.id
  description              = "PostgreSQL access from application servers"
}

# Database Rules - Legacy backend security group (for backward compatibility)
resource "aws_security_group_rule" "database_from_backend" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.backend.id
  security_group_id        = aws_security_group.database.id
  description              = "PostgreSQL access from backend (legacy)"
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
