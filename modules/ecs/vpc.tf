# Fetch AZs in the current region
data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr

  tags = {
    Name = format("%s-%s-VPC", var.app_name, var.environment)
  }
}

# Create var.az_count private subnets, each in a different AZ
resource "aws_subnet" "private" {
  for_each = toset(var.private_subnet_CIDR)

  vpc_id                  = aws_vpc.main.id
  availability_zone       = element(data.aws_availability_zones.available.names, index(var.private_subnet_CIDR, each.key))
  cidr_block              = each.key
  map_public_ip_on_launch = false

  tags = {
    Name = format("%s-%s-private", var.app_name, var.environment)
  }
}

# Create var.az_count public subnets, each in a different AZ
resource "aws_subnet" "public" {
  for_each = toset(var.public_subnet_CIDR)

  vpc_id                  = aws_vpc.main.id
  availability_zone       = element(data.aws_availability_zones.available.names, index(var.public_subnet_CIDR, each.key))
  cidr_block              = each.key
  map_public_ip_on_launch = true

  tags = {
    Name = format("%s-%s-public", var.app_name, var.environment)
  }
}

# Internet Gateway for the public subnet
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = format("%s-%s-gw", var.app_name, var.environment)
  }
}

# Route the public subnet traffic through the IGW
resource "aws_route" "internet_access" {
  route_table_id         = aws_vpc.main.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gw.id
}

# Create a NAT gateway with an Elastic IP for each private subnet to get internet connectivity
resource "aws_eip" "gw" {
  vpc        = true
  depends_on = [aws_internet_gateway.gw]

  tags = {
    Name = format("%s-%s-EIP", var.app_name, var.environment)
  }
}

resource "aws_nat_gateway" "gw" {
  allocation_id = aws_eip.gw.id
  subnet_id     = aws_subnet.public[element(var.public_subnet_CIDR, 1)].id

  tags = {
    Name = format("%s-%s-NGW", var.app_name, var.environment)
  }
}

# Create a new route table for the private subnets, make it route non-local traffic through the NAT gateway to the internet
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.gw.id
  }

  tags = {
    Name = format("%s-%s-RT", var.app_name, var.environment)
  }
}

# Explicitly associate the newly created route tables to the private subnets (so they don't default to the main route table)
resource "aws_route_table_association" "private" {
  for_each = toset(var.private_subnet_CIDR)

  route_table_id = aws_route_table.private.id
  subnet_id      = aws_subnet.private[each.value].id
}

