resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support

  tags = merge(
    {
      Name        = var.vpc_name
      Environment = var.environment
    },
    var.tags
  )
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    {
      Name        = "${var.vpc_name}-igw"
      Environment = var.environment
    },
    var.tags
  )
}

# Public Subnets
resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = merge(
    {
      Name        = "${var.vpc_name}-public-${var.availability_zones[count.index]}"
      Environment = var.environment
      Type        = "Public"
    },
    var.tags
  )
}

# Private Subnets
resource "aws_subnet" "private" {
  count                   = length(var.private_subnet_cidrs)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.private_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = false

  tags = merge(
    {
      Name        = "${var.vpc_name}-private-${var.availability_zones[count.index]}"
      Environment = var.environment
      Type        = "Private"
    },
    var.tags
  )
}

# Route Table for Public Subnets
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    {
      Name        = "${var.vpc_name}-public-rt"
      Environment = var.environment
    },
    var.tags
  )
}

# Route to Internet Gateway for Public Subnets
resource "aws_route" "public_internet_gateway" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}

# Route Table for Private Subnets
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    {
      Name        = "${var.vpc_name}-private-rt"
      Environment = var.environment
    },
    var.tags
  )
}

# Associate Public Subnets with Public Route Table
resource "aws_route_table_association" "public" {
  count          = length(var.public_subnet_cidrs)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Associate Private Subnets with Private Route Table
resource "aws_route_table_association" "private" {
  count          = length(var.private_subnet_cidrs)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

# VPC Flow Logs
resource "aws_flow_log" "main" {
  iam_role_arn    = aws_iam_role.flow_log.arn
  log_destination = aws_cloudwatch_log_group.flow_log.arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.main.id
}

# CloudWatch Log Group for VPC Flow Logs
resource "aws_cloudwatch_log_group" "flow_log" {
  name              = "/aws/vpc-flow-log/${var.vpc_name}"
  retention_in_days = 30

  tags = merge(
    {
      Name        = "${var.vpc_name}-flow-log"
      Environment = var.environment
    },
    var.tags
  )
}

# IAM Role for VPC Flow Logs
resource "aws_iam_role" "flow_log" {
  name = "${var.vpc_name}-flow-log-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(
    {
      Name        = "${var.vpc_name}-flow-log-role"
      Environment = var.environment
    },
    var.tags
  )
}

# IAM Policy for VPC Flow Logs
resource "aws_iam_role_policy" "flow_log" {
  name = "${var.vpc_name}-flow-log-policy"
  role = aws_iam_role.flow_log.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}
