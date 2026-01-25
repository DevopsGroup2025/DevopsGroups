resource "aws_db_subnet_group" "main" {
  name       = "main-db-subnet-group-${var.project_name}"
  subnet_ids = var.private_subnet_ids
  tags = { Name = "main-db-subnet-group-${var.project_name}" }
}

resource "aws_db_instance" "postgres" {
  identifier             = "main-postgres-${var.project_name}"
  engine                 = "postgres"
  engine_version         = "15.15"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  storage_type           = "gp2"
  
  db_name  = "appdb"
  username = var.db_username
  password = var.db_password
  
  vpc_security_group_ids = [var.db_security_group_id]
  db_subnet_group_name   = aws_db_subnet_group.main.name
  
  skip_final_snapshot = true
  deletion_protection = false
  
  tags = { Name = "main-postgres-${var.project_name}" }
}