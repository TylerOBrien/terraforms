resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = join("-", [var.name_prefix, "igw"])
  }
}
