resource "aws_db_subnet_group" "main" {
	name       = "${var.db_name}-subnet-group"
	subnet_ids = var.private_subnet_ids
	tags = {
		Name = "${var.db_name}-subnet-group"
	}
}

resource "aws_db_instance" "main" {
	identifier              = var.db_name
	engine                  = "postgres"
	instance_class          = var.db_instance_class
	username                = var.db_username
	password                = var.db_password
	db_subnet_group_name    = aws_db_subnet_group.main.name
	vpc_security_group_ids  = var.security_group_ids
	allocated_storage       = 20
	max_allocated_storage   = 100
	storage_encrypted       = true
	skip_final_snapshot     = true
	publicly_accessible     = false
	multi_az                = false
	auto_minor_version_upgrade = true
	backup_retention_period = 7
	tags = {
		Name = var.db_name
	}
}

output "rds_endpoint" {
	value = aws_db_instance.main.endpoint
}

output "rds_port" {
	value = aws_db_instance.main.port
}
