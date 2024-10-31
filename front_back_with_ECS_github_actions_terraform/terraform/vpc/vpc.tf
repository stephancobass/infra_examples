# Fetch availability zones in the current region.
resource "aws_vpc" "app" {
  count      = var.env_name == "stage" ? 1 : (var.env_name == "prod" ? 1 : 0)
  cidr_block = var.vpc_cidr
  
  tags = {
    Name = "${var.env_name}-${var.app_name}-vpc"
  }
}

# Create az_count public subnets in /21 prefix CIDR for each availability zone
resource "aws_subnet" "public" {
  count                   = var.env_name == "stage" ? var.az_count : (var.env_name == "prod" ? var.az_count : 0)
  cidr_block              = cidrsubnet(var.vpc_cidr, 4, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  vpc_id                  = aws_vpc.app.0.id
  map_public_ip_on_launch = true

  tags = merge(local.common_tags, {
    Name = "${var.env_name} ${var.app_name} public subnet ${count.index + 1}"
    Tier = "Public"
  })
}

# Create private subnets for each availability zone.
resource "aws_subnet" "private" {
  count             = var.env_name == "stage" ? var.az_count : (var.env_name == "prod" ? var.az_count : 0)
  cidr_block        = cidrsubnet(var.app_cidr, 2, count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]
  vpc_id            = aws_vpc.app.0.id

  tags = merge(local.common_tags, {
    Name = "${var.env_name} ${var.app_name} private subnet ${count.index + 1}"
    Tier = "Private"
  })
}

resource "aws_internet_gateway" "igw" {
  count  = var.env_name == "stage" ? 1 : (var.env_name == "prod" ? 1 : 0)
  vpc_id = aws_vpc.app.0.id

  tags = merge(local.common_tags, {
    Name = "${var.env_name} ${var.app_name} igw"
  })
}

resource "aws_eip" "eip" {
  count      = var.env_name == "stage" ? 1 : (var.env_name == "prod" ? 1 : 0)
  domain        = "vpc"
  depends_on = [aws_internet_gateway.igw]
  
  tags = merge(local.common_tags, {
    Name = "${var.env_name} ${var.app_name} eip"
  })
}


resource "aws_nat_gateway" "natgw" {
  count         = var.env_name == "stage" ? 1 : (var.env_name == "prod" ? 1 : 0)
  subnet_id     = aws_subnet.public.0.id
  allocation_id = aws_eip.eip.0.id

  tags = merge(local.common_tags, {
    Name = "${var.env_name} ${var.app_name} nat"
  })
}


# Create a new route table for the private subnets.
# And make it route non-local traffic through the NAT gateway to the internet.
resource "aws_route_table" "private" {
  count  = var.env_name == "stage" ? var.az_count : (var.env_name == "prod" ? var.az_count : 0)
  vpc_id = aws_vpc.app.0.id

  tags = merge(local.common_tags, {
    Name = "${var.env_name} ${var.app_name} private route table ${count.index + 1}"
  })
}

resource "aws_route" "nat_route" {
  count  = var.env_name == "stage" ? var.az_count : (var.env_name == "prod" ? var.az_count : 0)
  route_table_id = aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_nat_gateway.natgw.0.id
}


resource "aws_route_table" "public" {
  count  = var.env_name == "stage" ? var.az_count : (var.env_name == "prod" ? var.az_count : 0)
  vpc_id = aws_vpc.app.0.id

  tags = merge(local.common_tags, {
    Name = "${var.env_name} ${var.app_name} public route table ${count.index + 1}"
  })
}

resource "aws_route" "igw_route" {
  count  = var.env_name == "stage" ? var.az_count : (var.env_name == "prod" ? var.az_count : 0)
  route_table_id = aws_route_table.public[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.igw.0.id
}


# Explicitely associate the newly created route tables to the private subnets (so they don't default to the main route table).
resource "aws_route_table_association" "private" {
  count          = var.env_name == "stage" ? length(aws_subnet.private.*.id) : (var.env_name == "prod" ? length(aws_subnet.private.*.id) : 0)
  subnet_id      = element(aws_subnet.private.*.id, count.index)
  route_table_id = element(aws_route_table.private.*.id, count.index)
}

resource "aws_route_table_association" "public" {
  count          = var.env_name == "stage" ? length(aws_subnet.public.*.id) : (var.env_name == "prod" ? length(aws_subnet.public.*.id) : 0)
  subnet_id      = element(aws_subnet.public.*.id, count.index)
  route_table_id = element(aws_route_table.public.*.id, count.index)
}


resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.app.0.id
  service_name = "com.amazonaws.${local.region}.s3"

  tags = merge(local.common_tags, {
    Name = "${var.env_name} ${var.app_name} vpc endpoint"
  })
}

resource "aws_vpc_endpoint_route_table_association" "vpc_endpoint_to_s3" {
  count          = var.env_name == "stage" ? length(aws_subnet.private.*.id) : (var.env_name == "prod" ? length(aws_subnet.private.*.id) : 0)
  route_table_id  = aws_route_table.private[count.index].id
  vpc_endpoint_id = aws_vpc_endpoint.s3.id
}