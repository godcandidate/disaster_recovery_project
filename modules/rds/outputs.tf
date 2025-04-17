output "db_subnet_group_id" {
  description = "ID of the DB subnet group"
  value       = aws_db_subnet_group.this.id
}

output "db_parameter_group_id" {
  description = "ID of the DB parameter group"
  value       = aws_db_parameter_group.this.id
}


output "primary_db_instance_id" {
  description = "ID of the primary DB instance"
  value       = var.environment == "primary" ? aws_db_instance.primary[0].id : null
}

output "primary_db_instance_address" {
  description = "Address of the primary DB instance"
  value       = var.environment == "primary" ? aws_db_instance.primary[0].address : null
}

output "primary_db_instance_endpoint" {
  description = "Endpoint of the primary DB instance"
  value       = var.environment == "primary" ? aws_db_instance.primary[0].endpoint : null
}

output "primary_db_instance_arn" {
  description = "ARN of the primary DB instance"
  value       = var.environment == "primary" ? aws_db_instance.primary[0].arn : null
}

output "read_replica_db_instance_id" {
  description = "ID of the read replica DB instance"
  value       = var.environment == "dr" && var.is_read_replica ? aws_db_instance.read_replica[0].id : null
}

output "read_replica_db_instance_address" {
  description = "Address of the read replica DB instance"
  value       = var.environment == "dr" && var.is_read_replica ? aws_db_instance.read_replica[0].address : null
}

output "read_replica_db_instance_endpoint" {
  description = "Endpoint of the read replica DB instance"
  value       = var.environment == "dr" && var.is_read_replica ? aws_db_instance.read_replica[0].endpoint : null
}

output "backup_replication_kms_key_arn" {
  description = "ARN of the KMS key used for backup replication"
  value       = var.environment == "primary" && var.enable_cross_region_backup ? aws_kms_key.backup_replication[0].arn : null
}
