resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(var.tags, {
    Name = "${var.project_prefix}-vpc"
  })
}
data "aws_availability_zones" "available" {
  state = "available"
}

# Public Subnets
resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_prefix}-public-a"
    Tier = "public"
  }
}

resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_prefix}-public-b"
    Tier = "public"
  }
}

# Private Subnets
resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = "10.0.11.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "${var.project_prefix}-private-a"
    Tier = "private"
  }
}

resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = "10.0.12.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name = "${var.project_prefix}-private-b"
    Tier = "private"
  }
}
# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.this.id
  tags = {
    Name = "${var.project_prefix}-igw"
  }
}

# Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  tags = {
    Name = "${var.project_prefix}-rt-public"
  }
}

# Default route to Internet via IGW
resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

# Associate BOTH public subnets to the public RT
resource "aws_route_table_association" "public_a_assoc" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_b_assoc" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}
# ----- Step 6: NAT Gateways + Private Route Tables -----

# Elastic IP for NAT in AZ a
resource "aws_eip" "nat_eip_a" {
  domain = "vpc"
  tags = {
    Name = "${var.project_prefix}-nat-eip-a"
  }
}

# Elastic IP for NAT in AZ b
resource "aws_eip" "nat_eip_b" {
  domain = "vpc"
  tags = {
    Name = "${var.project_prefix}-nat-eip-b"
  }
}

# NAT Gateway in Public Subnet A
resource "aws_nat_gateway" "nat_a" {
  allocation_id = aws_eip.nat_eip_a.id
  subnet_id     = aws_subnet.public_a.id

  tags = {
    Name = "${var.project_prefix}-nat-a"
  }

  depends_on = [aws_internet_gateway.igw]
}

# NAT Gateway in Public Subnet B
resource "aws_nat_gateway" "nat_b" {
  allocation_id = aws_eip.nat_eip_b.id
  subnet_id     = aws_subnet.public_b.id

  tags = {
    Name = "${var.project_prefix}-nat-b"
  }

  depends_on = [aws_internet_gateway.igw]
}

# Private Route Table (AZ A)
resource "aws_route_table" "private_a" {
  vpc_id = aws_vpc.this.id
  tags = {
    Name = "${var.project_prefix}-rt-private-a"
  }
}

# Route private traffic in AZ A - NAT A
resource "aws_route" "private_a_route" {
  route_table_id         = aws_route_table.private_a.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_a.id
}

# Associate Private Subnet A with RT A
resource "aws_route_table_association" "private_a_assoc" {
  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.private_a.id
}

# Private Route Table (AZ B)
resource "aws_route_table" "private_b" {
  vpc_id = aws_vpc.this.id
  tags = {
    Name = "${var.project_prefix}-rt-private-b"
  }
}

# Route private traffic in AZ B - NAT B
resource "aws_route" "private_b_route" {
  route_table_id         = aws_route_table.private_b.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_b.id
}

# Associate Private Subnet B with RT B
resource "aws_route_table_association" "private_b_assoc" {
  subnet_id      = aws_subnet.private_b.id
  route_table_id = aws_route_table.private_b.id
}
# Public-facing Load Balancer SG
resource "aws_security_group" "alb" {
  name        = "${var.project_prefix}-sg-alb"
  description = "ALB ingress 80/443 from internet"
  vpc_id      = aws_vpc.this.id

  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "HTTPS from internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_prefix}-sg-alb"
    Tier = "public"
  }
}

# App compute SG (EC2/ECS in private subnets)
resource "aws_security_group" "app" {
  name        = "${var.project_prefix}-sg-app"
  description = "App instances; allow HTTP from ALB only"
  vpc_id      = aws_vpc.this.id

  ingress {
    description     = "HTTP from ALB SG"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_prefix}-sg-app"
    Tier = "private"
  }
}

# Database SG
resource "aws_security_group" "db" {
  name        = "${var.project_prefix}-sg-db"
  description = "DB; allow 5432 from App SG"
  vpc_id      = aws_vpc.this.id

  ingress {
    description     = "Postgres from App SG"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_prefix}-sg-db"
    Tier = "db"
  }
}
