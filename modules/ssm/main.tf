# KMS Key for SSM Parameter Store
resource "aws_kms_key" "ssm" {
  count = var.kms_key_id == null ? 1 : 0

  description             = "KMS key for SSM Parameter Store in ${var.environment} environment"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  tags = merge(
    {
      Name        = "dr-ssm-key-${var.environment}"
      Environment = var.environment
    },
    var.tags
  )
}

resource "aws_kms_alias" "ssm" {
  count = var.kms_key_id == null ? 1 : 0

  name          = "alias/dr-ssm-key-${var.environment}"
  target_key_id = aws_kms_key.ssm[0].key_id
}

locals {
  kms_key_id = var.kms_key_id != null ? var.kms_key_id : (var.kms_key_id == null ? aws_kms_key.ssm[0].key_id : null)
  parameter_prefix = "/dr/database"
  s3_parameter_prefix = "/dr/s3"
}

# SSM Parameters for Database Connection
resource "aws_ssm_parameter" "db_host" {
  name        = "${local.parameter_prefix}/host"
  description = "Database host for ${var.environment} environment"
  type        = "String"
  value       = var.db_endpoint != null ? var.db_endpoint : "pending-endpoint"
  # No KMS key for String type

  tags = merge(
    {
      Name        = "dr-db-host-${var.environment}"
      Environment = var.environment
    },
    var.tags
  )
}

resource "aws_ssm_parameter" "db_port" {
  name        = "${local.parameter_prefix}/port"
  description = "Database port for ${var.environment} environment"
  type        = "String"
  value       = var.db_port
  # No KMS key for String type

  tags = merge(
    {
      Name        = "dr-db-port-${var.environment}"
      Environment = var.environment
    },
    var.tags
  )
}

resource "aws_ssm_parameter" "db_name" {
  name        = "${local.parameter_prefix}/name"
  description = "Database name for ${var.environment} environment"
  type        = "String"
  value       = var.db_name
  # No KMS key for String type

  tags = merge(
    {
      Name        = "dr-db-name-${var.environment}"
      Environment = var.environment
    },
    var.tags
  )
}

resource "aws_ssm_parameter" "db_username" {
  name        = "${local.parameter_prefix}/username"
  description = "Database username for ${var.environment} environment"
  type        = "SecureString"
  value       = var.db_username
  # Using default AWS KMS key for SecureString

  tags = merge(
    {
      Name        = "dr-db-username-${var.environment}"
      Environment = var.environment
    },
    var.tags
  )
}

resource "aws_ssm_parameter" "db_password" {
  name        = "${local.parameter_prefix}/password"
  description = "Database password for ${var.environment} environment"
  type        = "SecureString"
  value       = var.db_password
  # Using default AWS KMS key for SecureString

  tags = merge(
    {
      Name        = "dr-db-password-${var.environment}"
      Environment = var.environment
    },
    var.tags
  )
}

# Connection string in various formats
resource "aws_ssm_parameter" "db_connection_string_mysql" {
  name        = "${local.parameter_prefix}/connection_string/mysql"
  description = "MySQL connection string for ${var.environment} environment"
  type        = "SecureString"
  value       = "mysql://${var.db_username}:${var.db_password}@${var.db_endpoint != null ? var.db_endpoint : "pending-endpoint"}:${var.db_port}/${var.db_name}"
  # Using default AWS KMS key for SecureString

  tags = merge(
    {
      Name        = "dr-db-connection-mysql-${var.environment}"
      Environment = var.environment
    },
    var.tags
  )
}

resource "aws_ssm_parameter" "db_connection_string_jdbc" {
  name        = "${local.parameter_prefix}/connection_string/jdbc"
  description = "JDBC connection string for ${var.environment} environment"
  type        = "SecureString"
  value       = "jdbc:mysql://${var.db_endpoint != null ? var.db_endpoint : "pending-endpoint"}:${var.db_port}/${var.db_name}"
  # Using default AWS KMS key for SecureString

  tags = merge(
    {
      Name        = "dr-db-connection-jdbc-${var.environment}"
      Environment = var.environment
    },
    var.tags
  )
}

# S3 Parameters for Image Gallery Application
resource "aws_ssm_parameter" "s3_bucket_id" {
  name        = "${local.s3_parameter_prefix}/bucket_id"
  description = "S3 bucket ID for image gallery in ${var.environment} environment"
  type        = "String"
  value       = var.s3_bucket_id != "" ? var.s3_bucket_id : "pending-bucket-id"

  tags = merge(
    {
      Name        = "dr-s3-bucket-id-${var.environment}"
      Environment = var.environment
    },
    var.tags
  )
}

resource "aws_ssm_parameter" "s3_bucket_region" {
  name        = "${local.s3_parameter_prefix}/bucket_region"
  description = "S3 bucket region for image gallery in ${var.environment} environment"
  type        = "String"
  value       = var.s3_bucket_region != "" ? var.s3_bucket_region : var.region

  tags = merge(
    {
      Name        = "dr-s3-bucket-region-${var.environment}"
      Environment = var.environment
    },
    var.tags
  )
}
