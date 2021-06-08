resource "aws_subnet" "main" {
  count = length(var.availability_zones)

  vpc_id     = aws_vpc.main.id
  cidr_block = cidrsubnet(aws_vpc.main.cidr_block, 4, count.index)

  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = var.map_public_ip_on_launch

  tags = {
    Name = join("-", [var.name_prefix, "subnet"])
  }
}
