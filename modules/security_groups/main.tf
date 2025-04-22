# Security Group for Load Balancer
resource "aws_security_group" "lb" {
  name        = "lb-sg-${var.environment}"
  description = "Security group for Load Balancer in ${var.environment} environment"
  vpc_id      = var.vpc_id

  # Allow HTTP inbound traffic
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP"
  }

  # Allow HTTPS inbound traffic
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS"
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = merge(
    {
      Name        = "lb-sg-${var.environment}"
      Environment = var.environment
    },
    var.tags
  )
}

# Security Group for EC2 instances
resource "aws_security_group" "ec2" {
  name        = "ec2-sg-${var.environment}"
  description = "Security group for EC2 instances in ${var.environment} environment"
  vpc_id      = var.vpc_id

  # Allow HTTP inbound traffic
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP"
  }

  # Allow HTTP inbound traffic for backend
  ingress {
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP"
  }


  # Allow SSH inbound traffic from restricted IPs
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH"
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = merge(
    {
      Name        = "ec2-sg-${var.environment}"
      Environment = var.environment
    },
    var.tags
  )
}

# Security Group for RDS instances
resource "aws_security_group" "rds" {
  name        = "rds-sg-${var.environment}"
  description = "Security group for RDS instances in ${var.environment} environment"
  vpc_id      = var.vpc_id

  # Allow database traffic from EC2 security group
  ingress {
    from_port       = var.db_port
    to_port         = var.db_port
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2.id]
    description     = "DB access from EC2 instances"
  }

  # Allow database traffic from VPC CIDR (for cross-AZ communication)
  ingress {
    from_port   = var.db_port
    to_port     = var.db_port
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "DB access from within VPC"
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = merge(
    {
      Name        = "rds-sg-${var.environment}"
      Environment = var.environment
    },
    var.tags
  )
}

# Security Group for Lambda functions
resource "aws_security_group" "lambda" {
  name        = "lambda-sg-${var.environment}"
  description = "Security group for Lambda functions in ${var.environment} environment"
  vpc_id      = var.vpc_id

  # Lambda functions typically don't need inbound rules
  # but we'll add outbound rules for S3, CloudWatch, etc.

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = merge(
    {
      Name        = "lambda-sg-${var.environment}"
      Environment = var.environment
    },
    var.tags
  )
}
