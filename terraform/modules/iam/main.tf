<<<<<<< HEAD
resource "aws_iam_role" "ec2_role" {
  name = "ec2-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_policy" "ec2_policy" {
  name = "ec2-policy"
=======
# =============================================================================
# IAM Module - Instance Profiles and Roles for EC2
# =============================================================================
# Creates IAM roles and instance profiles for EC2 instances
# Follows AWS security best practices with least privilege principle
# =============================================================================

# -----------------------------------------------------------------------------
# EC2 Instance Role - For application servers
# -----------------------------------------------------------------------------
resource "aws_iam_role" "ec2_role" {
  name = "${var.project_name}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-ec2-role"
    }
  )
}

# -----------------------------------------------------------------------------
# ECR Read-Only Policy - Allow pulling images from ECR
# -----------------------------------------------------------------------------
resource "aws_iam_role_policy_attachment" "ecr_read" {
  count = var.enable_ecr_access ? 1 : 0

  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# -----------------------------------------------------------------------------
# SSM Policy - Allow Systems Manager for secure access (optional)
# -----------------------------------------------------------------------------
resource "aws_iam_role_policy_attachment" "ssm" {
  count = var.enable_ssm_access ? 1 : 0

  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# -----------------------------------------------------------------------------
# CloudWatch Logs Policy - Allow sending logs to CloudWatch
# -----------------------------------------------------------------------------
resource "aws_iam_role_policy_attachment" "cloudwatch_logs" {
  count = var.enable_cloudwatch_logs ? 1 : 0

  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}

# -----------------------------------------------------------------------------
# Custom Policy for Secrets Manager (if enabled)
# -----------------------------------------------------------------------------
resource "aws_iam_role_policy" "secrets_manager" {
  count = var.enable_secrets_manager ? 1 : 0

  name = "${var.project_name}-secrets-policy"
  role = aws_iam_role.ec2_role.id

>>>>>>> 75f3543 (full clear workflow)
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
<<<<<<< HEAD
=======
        Sid    = "GetSecrets"
>>>>>>> 75f3543 (full clear workflow)
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
<<<<<<< HEAD
        Resource = var.secret_arn
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = "*"
=======
        Resource = var.secrets_arns
>>>>>>> 75f3543 (full clear workflow)
      }
    ]
  })
}

<<<<<<< HEAD
resource "aws_iam_role_policy_attachment" "ec2_policy_attachment" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.ec2_policy.arn
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2-profile"
  role = aws_iam_role.ec2_role.name
=======
# -----------------------------------------------------------------------------
# EC2 Instance Profile - Attach role to EC2 instances
# -----------------------------------------------------------------------------
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.project_name}-ec2-profile"
  role = aws_iam_role.ec2_role.name

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-ec2-profile"
    }
  )
}

# -----------------------------------------------------------------------------
# Bastion Role - Separate role for bastion host with additional permissions
# -----------------------------------------------------------------------------
resource "aws_iam_role" "bastion_role" {
  count = var.create_bastion_role ? 1 : 0

  name = "${var.project_name}-bastion-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-bastion-role"
    }
  )
}

# Bastion SSM access
resource "aws_iam_role_policy_attachment" "bastion_ssm" {
  count = var.create_bastion_role && var.enable_ssm_access ? 1 : 0

  role       = aws_iam_role.bastion_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Bastion Instance Profile
resource "aws_iam_instance_profile" "bastion_profile" {
  count = var.create_bastion_role ? 1 : 0

  name = "${var.project_name}-bastion-profile"
  role = aws_iam_role.bastion_role[0].name

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-bastion-profile"
    }
  )
>>>>>>> 75f3543 (full clear workflow)
}
