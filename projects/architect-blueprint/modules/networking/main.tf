# --- Retrieve available AZs in the current region
data "aws_availability_zones" "available" {
  state = "available"
}

# --- VPC: foundation of the network with DNS support enabled
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}-${var.environment}-vpc"
  }
}

# --- Database subnets are isolated — dedicated route table with NO default route
resource "aws_route_table" "database" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-${var.environment}-rt-database"
  }
}

# --- Public subnets — one per AZ, Transit-Gateway-ready (no public IP by default)
resource "aws_subnet" "public" {
  count = 3

  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = false

  tags = {
    Name                     = "${var.project_name}-${var.environment}-public-${count.index + 1}"
    "kubernetes.io/role/elb" = "1"
  }
}

# --- Private subnets — workloads (EKS nodes) live here; tagged for internal ALB
resource "aws_subnet" "private" {
  count = 3

  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 10)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name                              = "${var.project_name}-${var.environment}-private-${count.index + 1}"
    "kubernetes.io/role/internal-elb" = "1" # required for EKS ALB controller
  }
}

# --- Database subnets — isolated tier, no route to internet
resource "aws_subnet" "database" {
  count = 3

  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 20)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "${var.project_name}-${var.environment}-database-${count.index + 1}"
  }
}

# --- Internet Gateway — allows public subnets to reach the internet
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-${var.environment}-igw"
  }
}

# --- Elastic IPs for NAT Gateways (one per AZ for high availability)
# Cost: ~$3.65/month per EIP when associated with a running NAT Gateway
resource "aws_eip" "nat" {
  count  = var.enable_nat_gateway ? 3 : 0
  domain = "vpc"

  tags = {
    Name = "${var.project_name}-${var.environment}-nat-eip-${count.index + 1}"
  }

  depends_on = [aws_internet_gateway.main]
}

# --- NAT Gateways — one per AZ ensures no cross-AZ traffic for outbound calls
# Cost: ~$33/month each × 3 AZs = ~$99/month total
resource "aws_nat_gateway" "main" {
  count = var.enable_nat_gateway ? 3 : 0

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = {
    Name = "${var.project_name}-${var.environment}-nat-${count.index + 1}"
  }

  depends_on = [aws_internet_gateway.main]
}

# --- Public route table — default route via Internet Gateway
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-rt-public"
  }
}

# --- Private route tables — one per AZ so each AZ uses its local NAT Gateway
resource "aws_route_table" "private" {
  count  = var.enable_nat_gateway ? 3 : 1
  vpc_id = aws_vpc.main.id

  dynamic "route" {
    for_each = var.enable_nat_gateway ? [count.index] : []
    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = aws_nat_gateway.main[route.value].id
    }
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-rt-private-${count.index + 1}"
  }
}

# --- Route table associations: public subnets → public RT
resource "aws_route_table_association" "public" {
  count = 3

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# --- Route table associations: private subnets → per-AZ private RT
resource "aws_route_table_association" "private" {
  count = 3

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = var.enable_nat_gateway ? aws_route_table.private[count.index].id : aws_route_table.private[0].id
}

# --- Route table associations: database subnets → isolated RT (no internet route)
resource "aws_route_table_association" "database" {
  count = 3

  subnet_id      = aws_subnet.database[count.index].id
  route_table_id = aws_route_table.database.id
}

# --- CloudWatch Log Group for VPC Flow Logs (retention: 90 days)
resource "aws_cloudwatch_log_group" "flow_logs" {
  name              = "/aws/vpc/${var.project_name}-${var.environment}/flow-logs"
  retention_in_days = var.flow_log_retention_days

  tags = {
    Name = "${var.project_name}-${var.environment}-flow-logs"
  }
}

# --- IAM role allowing the VPC Flow Logs service to write to CloudWatch
resource "aws_iam_role" "flow_logs" {
  name = "${var.project_name}-${var.environment}-flow-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "vpc-flow-logs.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "flow_logs" {
  name = "${var.project_name}-${var.environment}-flow-logs-policy"
  role = aws_iam_role.flow_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams",
      ]
      Resource = "*"
    }]
  })
}

# --- VPC Flow Log — captures ALL traffic for security auditing and troubleshooting
resource "aws_flow_log" "main" {
  iam_role_arn    = aws_iam_role.flow_logs.arn
  log_destination = aws_cloudwatch_log_group.flow_logs.arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-${var.environment}-flow-log"
  }
}

# --- DB Subnet Group — registers isolated database subnets with RDS Aurora
resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-${var.environment}-db-subnet-group"
  subnet_ids = aws_subnet.database[*].id

  tags = {
    Name = "${var.project_name}-${var.environment}-db-subnet-group"
  }
}

# --- Bastion security group — SSH access restricted to approved CIDRs only
resource "aws_security_group" "bastion" {
  count = length(var.allowed_cidr_blocks) > 0 ? 1 : 0

  name        = "${var.project_name}-${var.environment}-bastion-sg"
  description = "Bastion host: SSH from approved CIDRs only"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH from approved CIDRs"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  egress {
    description = "Allow egress to private subnets only"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = aws_subnet.private[*].cidr_block
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-bastion-sg"
  }
}
