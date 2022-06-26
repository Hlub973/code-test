provider "aws" {
  region = var.region
}

# create vpc
resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  tags = {
    Name = "test_vpc"
  }
}

# create internet gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "test_igw"
  }
}

# create subnets
resource "aws_subnet" "subnet_a" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.subnet_cidr_a
  availability_zone = "${var.region}a"
  tags = {
    Name = "test_public_subnet"
  }
}

resource "aws_subnet" "subnet_b" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.subnet_cidr_b
  availability_zone = "${var.region}b"
  tags = {
    Name = "test_private_subnet"
  }
}

resource "aws_subnet" "subnet_c" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.subnet_cidr_c
  availability_zone = "${var.region}c"
  tags = {
    Name = "test_database_subnet"
  }
}

# create elastic IP for NAT gateway
resource "aws_eip" "nat-gw-eip" {
  vpc        = true
  depends_on = [aws_internet_gateway.igw]
  tags = {
    Name = "test_nat_gw_eip"
  }
}

# create NAT gateway
resource "aws_nat_gateway" "nat-gw" {
  allocation_id = aws_eip.nat-gw-eip.id
  subnet_id     = aws_subnet.subnet_b.id
  depends_on    = [aws_internet_gateway.igw]
  tags = {
    Name = "test_nat_gw"
  }
}

# create private route table
resource "aws_route_table" "private-rtb" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat-gw.id
  }
  tags = {
    Name = "test_private_route_table"
  }
}

# create route table for the public subnets
resource "aws_route_table" "public-rtb" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "test_public_route_table"
  }
}

# associate subnet_a to the public route table
resource "aws_route_table_association" "subnet_a_route_table_association" {
  subnet_id      = aws_subnet.subnet_a.id
  route_table_id = aws_route_table.public-rtb.id
}

# associate subnet_b to the private route table
resource "aws_route_table_association" "subnet_b_route_table_association" {
  subnet_id      = aws_subnet.subnet_b.id
  route_table_id = aws_route_table.private-rtb.id
}
