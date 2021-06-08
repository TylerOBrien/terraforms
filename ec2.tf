/*
|--------------------------------------------------------------------------
| Bastion
|--------------------------------------------------------------------------
*/

resource "aws_instance" "bastion" {
  subnet_id     = aws_subnet.main[0].id
  ami           = var.aws_amis[join("-", [var.bastion_system, var.bastion_arch])]
  instance_type = "t2.micro"

  depends_on             = [aws_internet_gateway.main]
  vpc_security_group_ids = [aws_security_group.bastion.id]

  tags = {
    Name = join("-", [var.name_prefix, "bastion"])
  }
}

/*
|--------------------------------------------------------------------------
| API
|--------------------------------------------------------------------------
*/

resource "aws_instance" "api" {
  subnet_id     = aws_subnet.main[1].id
  ami           = var.aws_amis[join("-", [var.api_system, var.api_arch])]
  instance_type = "t2.micro"

  depends_on             = [aws_internet_gateway.main]
  vpc_security_group_ids = [aws_security_group.api.id]

  tags = {
    Name = join("-", [var.name_prefix, "api"])
  }
}
