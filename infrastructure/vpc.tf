resource "aws_vpc" "vpc" {
  tags = {
    "Name" = "PlanetMinecraft"
  }
}

resource "aws_internet_gateway" "gateway" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    "Name" = "OutOfThisWorldGalacticGateway"
  }
}

resource "aws_subnet" "akl_local" {
  vpc_id = aws_vpc.vpc.id
  cidr_block = "10.0.0.0/26"
  availability_zone = "ap-southeast-2-akl-1a"
  map_public_ip_on_launch = true
  tags = {
    "Name" = "akl-local"
  }
}

resource "aws_route_table" "akl_local_routes" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    "Name" = "akl-local-routes"
  }

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gateway.id
  }
}

resource "aws_route_table_association" "akl_subnet_routes" {
  route_table_id = aws_route_table.akl_local_routes.id
  subnet_id = aws_subnet.akl_local.id
}