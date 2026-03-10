resource "aws_vpc" "main" {
 cidr_block = "10.0.0.0/16"
 enable_dns_hostnames = true
}


resource "aws_subnet" "public1" {
 vpc_id = aws_vpc.main.id
 cidr_block = "10.0.1.0/24"
 availability_zone = "ap-southeast-2a"
 map_public_ip_on_launch = true
}

resource "aws_subnet" "public2" {
 vpc_id = aws_vpc.main.id
 cidr_block = "10.0.2.0/24"
 availability_zone = "ap-southeast-2b"
 map_public_ip_on_launch = true
}

resource "aws_subnet" "private1" {
 vpc_id = aws_vpc.main.id
 cidr_block = "10.0.3.0/24"
 availability_zone = "ap-southeast-2a"
}

resource "aws_subnet" "private2" {
 vpc_id = aws_vpc.main.id
 cidr_block = "10.0.4.0/24"
 availability_zone = "ap-southeast-2b"
}

resource "aws_internet_gateway" "igw" {
 vpc_id = aws_vpc.main.id
}

# NAT Gateway for Private Subnets (Required to pull ECR images)
resource "aws_eip" "nat" {
  domain = "vpc"
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public1.id # Must be in a public subnet
  depends_on    = [aws_internet_gateway.igw]
}

# Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

# Private Route Table
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }
}

# Associations
resource "aws_route_table_association" "pub1" {
  subnet_id      = aws_subnet.public1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "pub2" {
  subnet_id      = aws_subnet.public2.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "priv1" {
  subnet_id      = aws_subnet.private1.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "priv2" {
  subnet_id      = aws_subnet.private2.id
  route_table_id = aws_route_table.private.id
}


  
