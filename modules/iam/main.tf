# EC2 IAM Role for Disaster Recovery
resource "aws_iam_role" "ec2_dr_role" {
  name = "ec2-dr-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(
    {
      Name        = "ec2-dr-role-${var.environment}"
      Environment = var.environment
    },
    var.tags
  )
}

# EC2 Instance Profile
resource "aws_iam_instance_profile" "ec2_dr_profile" {
  name = "ec2-dr-profile-${var.environment}"
  role = aws_iam_role.ec2_dr_role.name
}

# Policy for EC2 to access S3
resource "aws_iam_policy" "ec2_s3_access" {
  name        = "ec2-s3-access-${var.environment}"
  description = "Policy for EC2 instances to access S3 buckets for DR"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ]
        Effect   = "Allow"
        Resource = [
          "arn:aws:s3:::dr-*",
          "arn:aws:s3:::dr-*/*"
        ]
      }
    ]
  })
}

# Policy for EC2 to access Systems Manager
resource "aws_iam_policy" "ec2_ssm_access" {
  name        = "ec2-ssm-access-${var.environment}"
  description = "Policy for EC2 instances to access Systems Manager for DR"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:ssm:*:*:parameter/dr-*"
      }
    ]
  })
}

# Policy for EC2 to access CloudWatch
resource "aws_iam_policy" "ec2_cloudwatch_access" {
  name        = "ec2-cloudwatch-access-${var.environment}"
  description = "Policy for EC2 instances to access CloudWatch for DR"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:logs:*:*:log-group:/aws/ec2/dr-*"
      }
    ]
  })
}

# Attach policies to EC2 role
resource "aws_iam_role_policy_attachment" "ec2_s3_attachment" {
  role       = aws_iam_role.ec2_dr_role.name
  policy_arn = aws_iam_policy.ec2_s3_access.arn
}

resource "aws_iam_role_policy_attachment" "ec2_ssm_attachment" {
  role       = aws_iam_role.ec2_dr_role.name
  policy_arn = aws_iam_policy.ec2_ssm_access.arn
}

resource "aws_iam_role_policy_attachment" "ec2_cloudwatch_attachment" {
  role       = aws_iam_role.ec2_dr_role.name
  policy_arn = aws_iam_policy.ec2_cloudwatch_access.arn
}

# RDS IAM Role for Disaster Recovery
resource "aws_iam_role" "rds_dr_role" {
  name = "rds-dr-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "rds.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(
    {
      Name        = "rds-dr-role-${var.environment}"
      Environment = var.environment
    },
    var.tags
  )
}

# Policy for RDS cross-region replication
resource "aws_iam_policy" "rds_replication" {
  name        = "rds-replication-${var.environment}"
  description = "Policy for RDS cross-region replication"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "rds:CreateDBSnapshot",
          "rds:CopyDBSnapshot",
          "rds:ModifyDBSnapshot",
          "rds:DeleteDBSnapshot",
          "rds:DescribeDBSnapshots"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

# Attach policy to RDS role
resource "aws_iam_role_policy_attachment" "rds_replication_attachment" {
  role       = aws_iam_role.rds_dr_role.name
  policy_arn = aws_iam_policy.rds_replication.arn
}

# Lambda IAM Role for Disaster Recovery
resource "aws_iam_role" "lambda_dr_role" {
  name = "lambda-dr-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(
    {
      Name        = "lambda-dr-role-${var.environment}"
      Environment = var.environment
    },
    var.tags
  )
}

# Policy for Lambda to access S3
resource "aws_iam_policy" "lambda_s3_access" {
  name        = "lambda-s3-access-${var.environment}"
  description = "Policy for Lambda functions to access S3 for DR"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Effect   = "Allow"
        Resource = [
          "arn:aws:s3:::dr-*",
          "arn:aws:s3:::dr-*/*"
        ]
      }
    ]
  })
}

# Policy for Lambda to access CloudWatch
resource "aws_iam_policy" "lambda_cloudwatch_access" {
  name        = "lambda-cloudwatch-access-${var.environment}"
  description = "Policy for Lambda functions to access CloudWatch for DR"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# Policy for Lambda to access Parameter Store/Secrets Manager
resource "aws_iam_policy" "lambda_secrets_access" {
  name        = "lambda-secrets-access-${var.environment}"
  description = "Policy for Lambda functions to access Parameter Store/Secrets Manager for DR"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:ssm:*:*:parameter/dr-*"
      },
      {
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:secretsmanager:*:*:secret:dr-*"
      }
    ]
  })
}

# Attach policies to Lambda role
resource "aws_iam_role_policy_attachment" "lambda_s3_attachment" {
  role       = aws_iam_role.lambda_dr_role.name
  policy_arn = aws_iam_policy.lambda_s3_access.arn
}

resource "aws_iam_role_policy_attachment" "lambda_cloudwatch_attachment" {
  role       = aws_iam_role.lambda_dr_role.name
  policy_arn = aws_iam_policy.lambda_cloudwatch_access.arn
}

resource "aws_iam_role_policy_attachment" "lambda_secrets_attachment" {
  role       = aws_iam_role.lambda_dr_role.name
  policy_arn = aws_iam_policy.lambda_secrets_access.arn
}

# Cross-region role assumption policy
resource "aws_iam_policy" "cross_region_assume_role" {
  name        = "cross-region-assume-role-${var.environment}"
  description = "Policy to allow cross-region role assumption for DR"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "sts:AssumeRole"
        Effect   = "Allow"
        Resource = "arn:aws:iam::*:role/*-dr-role-*"
      }
    ]
  })
}

# Attach cross-region policy to all DR roles
resource "aws_iam_role_policy_attachment" "ec2_cross_region_attachment" {
  role       = aws_iam_role.ec2_dr_role.name
  policy_arn = aws_iam_policy.cross_region_assume_role.arn
}

resource "aws_iam_role_policy_attachment" "rds_cross_region_attachment" {
  role       = aws_iam_role.rds_dr_role.name
  policy_arn = aws_iam_policy.cross_region_assume_role.arn
}

resource "aws_iam_role_policy_attachment" "lambda_cross_region_attachment" {
  role       = aws_iam_role.lambda_dr_role.name
  policy_arn = aws_iam_policy.cross_region_assume_role.arn
}
