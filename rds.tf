resource "aws_db_subnet_group" "main" {
  name = join("-", [var.name_prefix, "dbsbg"])
  subnet_ids = [
    aws_subnet.main[0].id,
    aws_subnet.main[1].id,
    aws_subnet.main[2].id
  ]

  tags = {
    Name = join("-", [var.name_prefix, "dbsbg"])
  }
}

resource "aws_db_instance" "mariadb" {
  identifier = join("-", [var.name_prefix, "mariadb"])

  allocated_storage     = 20
  max_allocated_storage = 500
  storage_type          = "gp2"
  instance_class        = "db.t3.micro"

  engine               = "mariadb"
  engine_version       = "10.4.13"
  parameter_group_name = "default.mariadb10.4"

  name     = var.db_name
  username = var.db_username
  password = var.db_password

  vpc_security_group_ids = [aws_security_group.db.id]
  db_subnet_group_name   = aws_db_subnet_group.main.name
  skip_final_snapshot    = true
}
