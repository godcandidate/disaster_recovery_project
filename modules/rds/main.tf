# Get current AWS account ID
data "aws_caller_identity" "current" {}

# RDS Subnet Group
resource "aws_db_subnet_group" "this" {
  name        = "dr-db-subnet-group-${var.environment}"
  description = "Subnet group for RDS in ${var.environment} environment"
  subnet_ids  = var.subnet_ids

  tags = merge(
    {
      Name        = "dr-db-subnet-group-${var.environment}"
      Environment = var.environment
    },
    var.tags
  )
}

# RDS Parameter Group
resource "aws_db_parameter_group" "this" {
  name        = "dr-db-parameter-group-${var.environment}"
  family      = "${var.db_engine}8.0"
  description = "Parameter group for RDS in ${var.environment} environment"

  # Example parameters for MySQL
  dynamic "parameter" {
    for_each = var.db_engine == "mysql" ? [1] : []
    content {
      name  = "max_connections"
      value = "100"
    }
  }

  tags = merge(
    {
      Name        = "dr-db-parameter-group-${var.environment}"
      Environment = var.environment
    },
    var.tags
  )
}

# DB Option Group removed as requested

# Primary RDS Instance
resource "aws_db_instance" "primary" {
  count = var.environment == "primary" ? 1 : 0

  identifier                  = "dr-db-${var.environment}"
  engine                      = var.db_engine
  engine_version              = var.db_engine_version
  instance_class              = var.db_instance_class
  allocated_storage           = var.db_allocated_storage
  storage_type                = var.db_storage_type
  db_name                     = var.db_name
  username                    = var.db_username
  password                    = var.db_password
  parameter_group_name        = aws_db_parameter_group.this.name
  # Option group removed as requested
  db_subnet_group_name        = aws_db_subnet_group.this.name
  vpc_security_group_ids      = [var.security_group_id]
  multi_az                    = var.db_multi_az
  backup_retention_period     = var.is_read_replica ? 0 : 1  # Minimum required for source DB with read replicas
  backup_window               = var.db_backup_window
  maintenance_window          = var.db_maintenance_window
  skip_final_snapshot         = true  # Skip final snapshot
  final_snapshot_identifier   = null  # No final snapshot needed
  copy_tags_to_snapshot       = true
  auto_minor_version_upgrade  = true
  deletion_protection         = false
  # Removed CloudWatch logs export
  # enabled_cloudwatch_logs_exports = ["audit", "error", "general", "slowquery"]

  tags = merge(
    {
      Name        = "dr-db-${var.environment}"
      Environment = var.environment
    },
    var.tags
  )
}

# Read Replica in DR Region
resource "aws_db_instance" "read_replica" {
  count = var.environment == "dr" && var.is_read_replica ? 1 : 0

  identifier                  = "dr-db-${var.environment}-replica"
  replicate_source_db         = "arn:aws:rds:${var.primary_region}:${data.aws_caller_identity.current.account_id}:db:${var.source_db_instance_identifier}"
  instance_class              = var.db_instance_class
  parameter_group_name        = aws_db_parameter_group.this.name
  # Option group removed as requested
  vpc_security_group_ids      = [var.security_group_id]
  db_subnet_group_name        = aws_db_subnet_group.this.name
  auto_minor_version_upgrade  = true
  backup_retention_period     = var.db_backup_retention_period
  backup_window               = var.db_backup_window
  maintenance_window          = var.db_maintenance_window
  skip_final_snapshot         = true  # Always skip final snapshot for read replica
  final_snapshot_identifier   = null  # No final snapshot needed
  copy_tags_to_snapshot       = true
  deletion_protection         = false  # Allow easy deletion for testing
  # Removed CloudWatch logs export
  # enabled_cloudwatch_logs_exports = ["audit", "error", "general", "slowquery"]

  lifecycle {
    ignore_changes = [
      replicate_source_db,
      parameter_group_name,
      vpc_security_group_ids,
      db_subnet_group_name,
      auto_minor_version_upgrade,
      backup_retention_period,
      backup_window,
      maintenance_window,
      skip_final_snapshot,
      final_snapshot_identifier,
      copy_tags_to_snapshot,
      deletion_protection,
      enabled_cloudwatch_logs_exports
    ]
  }

  tags = merge(
    {
      Name        = "dr-db-${var.environment}-replica"
      Environment = var.environment
      ReadReplica = "true"
    },
    var.tags
  )
}

# Cross-Region Automated Backup Replication
resource "aws_db_instance_automated_backups_replication" "this" {
  count = var.environment == "primary" && var.enable_cross_region_backup ? 1 : 0

  source_db_instance_arn = aws_db_instance.primary[0].arn
  retention_period       = var.db_backup_retention_period
  kms_key_id             = aws_kms_key.backup_replication[0].arn
}

# KMS Key for Cross-Region Backup Replication
resource "aws_kms_key" "backup_replication" {
  count = var.environment == "primary" && var.enable_cross_region_backup ? 1 : 0

  description             = "KMS key for RDS backup replication from ${var.primary_region} to ${var.region}"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = merge(
    {
      Name        = "dr-rds-backup-key-${var.environment}"
      Environment = var.environment
    },
    var.tags
  )
}

resource "aws_kms_alias" "backup_replication" {
  count = var.environment == "primary" && var.enable_cross_region_backup ? 1 : 0

  name          = "alias/dr-rds-backup-key-${var.environment}"
  target_key_id = aws_kms_key.backup_replication[0].key_id
}
