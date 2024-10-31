# VPC resources
resource "aws_vpc" "app" {
  cidr_block = var.vpc_cidr
  
  tags = {
    Name = "${var.env_name}-${var.app_name}-vpc"
  }
}

resource "aws_subnet" "public" {
  cidr_block              = var.vpc_cidr
  vpc_id                  = aws_vpc.app.id
  map_public_ip_on_launch = true

  tags = merge(local.common_tags, {
    Name = "${var.env_name} ${var.app_name} public subnet"
    Tier = "Public"
  })
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.app.id

  tags = merge(local.common_tags, {
    Name = "${var.env_name} ${var.app_name} igw"
  })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.app.id

  tags = merge(local.common_tags, {
    Name = "${var.env_name} ${var.app_name} public route table"
  })
}

resource "aws_route" "igw_route" {
  route_table_id = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.igw.id
}


resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}


resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.app.id
  service_name = "com.amazonaws.${local.region}.s3"

  tags = merge(local.common_tags, {
    Name = "${var.env_name} ${var.app_name} vpc endpoint"
  })
}

resource "aws_vpc_endpoint_route_table_association" "vpc_endpoint_to_s3" {
  route_table_id  = aws_route_table.public.id
  vpc_endpoint_id = aws_vpc_endpoint.s3.id
}