/*
|--------------------------------------------------------------------------
| Terraform
|--------------------------------------------------------------------------
*/

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }

  required_version = ">= 0.14.9"
}

/*
|--------------------------------------------------------------------------
| Variables
|--------------------------------------------------------------------------
*/

variable "availability_zones" {
  description = "A list of availability zones in which to create subnets"
  type        = list(string)
  default     = ["us-east-2a", "us-east-2b", "us-east-2c"]
}

variable "cidr_block" {
  description = "cidr"
  type        = string
  default     = "10.0.0.0/16"
}

/*
|--------------------------------------------------------------------------
| Provider
|--------------------------------------------------------------------------
*/

provider "aws" {
  profile = "default"
  region  = "us-east-2"
}

/*
|--------------------------------------------------------------------------
| VPC
|--------------------------------------------------------------------------
*/

resource "aws_vpc" "my_vpc" {
  cidr_block           = var.cidr_block
  enable_dns_hostnames = true


  tags = {
    Name = "dev-vpc"
  }
}

/*
|--------------------------------------------------------------------------
| Subnets
|--------------------------------------------------------------------------
*/

resource "aws_subnet" "my_subnet" {
  count      = length(var.availability_zones)
  vpc_id     = aws_vpc.my_vpc.id
  cidr_block = cidrsubnet(aws_vpc.my_vpc.cidr_block, 4, count.index)

  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "dev-subnet"
  }
}

/*
|--------------------------------------------------------------------------
| Internet Gateway
|--------------------------------------------------------------------------
*/

resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "dev-igw"
  }
}

/*
|--------------------------------------------------------------------------
| Route Table
|--------------------------------------------------------------------------
*/

resource "aws_route_table" "my_rtb" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_igw.id
  }

  tags = {
    Name = "dev-rtb"
  }
}

resource "aws_route_table_association" "my_rtb_assoc" {
  count          = length(aws_subnet.my_subnet)
  subnet_id      = aws_subnet.my_subnet[count.index].id
  route_table_id = aws_route_table.my_rtb.id
}

/*
|--------------------------------------------------------------------------
| Bastion
|--------------------------------------------------------------------------
*/

resource "aws_security_group" "sg_bastion" {
  name        = "dev-bastion-sg"
  description = "asdf"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.my_vpc.cidr_block]
  }

  egress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.my_vpc.cidr_block]
  }

  tags = {
    Name = "dev-bastion-sg"
  }
}

resource "aws_instance" "ec2_bastion" {
  subnet_id     = aws_subnet.my_subnet[0].id
  ami           = "ami-00399ec92321828f5" # Ubuntu 20.04
  instance_type = "t2.micro"

  vpc_security_group_ids = [aws_security_group.sg_bastion.id]
  depends_on             = [aws_internet_gateway.my_igw]

  tags = {
    Name = "dev-bastion"
  }
}

/*
|--------------------------------------------------------------------------
| API
|--------------------------------------------------------------------------
*/

resource "aws_security_group" "sg_api" {
  name        = "dev-sg-api"
  description = "asdf"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.sg_bastion.id]
  }

  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "dev-sg-api"
  }
}

resource "aws_instance" "ec2_api" {
  subnet_id     = aws_subnet.my_subnet[1].id
  ami           = "ami-00399ec92321828f5" # Ubuntu 20.04
  instance_type = "t2.micro"

  vpc_security_group_ids = [aws_security_group.sg_api.id]
  depends_on             = [aws_internet_gateway.my_igw]

  tags = {
    Name = "dev-api"
  }
}

/*
|--------------------------------------------------------------------------
| Database
|--------------------------------------------------------------------------
*/

resource "aws_security_group" "sg_mariadb" {
  name        = "dev-sg-mariadb"
  description = "asdf"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.sg_bastion.id]
  }

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.sg_api.id]
  }

  egress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.sg_bastion.id]
  }

  egress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.sg_api.id]
  }

  tags = {
    Name = "dev-sg-mariadb"
  }
}

resource "aws_db_subnet_group" "db_sbg" {
  name       = "db_sbg"
  subnet_ids = [aws_subnet.my_subnet[0].id, aws_subnet.my_subnet[1].id, aws_subnet.my_subnet[2].id]

  tags = {
    Name = "db_sbg"
  }
}

resource "aws_db_instance" "db_app" {
  allocated_storage     = 20
  max_allocated_storage = 500
  storage_type          = "gp2"

  identifier     = "dev-mariadb"
  engine         = "mariadb"
  engine_version = "10.4.13"
  instance_class = "db.t3.micro"

  name     = "mydb"
  username = "foo"
  password = "foobarbaz"

  vpc_security_group_ids = [aws_security_group.sg_mariadb.id]
  parameter_group_name   = "default.mariadb10.4"
  db_subnet_group_name   = aws_db_subnet_group.db_sbg.name
  skip_final_snapshot    = true
}
