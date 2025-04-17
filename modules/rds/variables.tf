variable "environment" {
  description = "Environment (primary or dr)"
  type        = string
}

variable "region" {
  description = "The AWS region to deploy resources in"
  type        = string
}

variable "primary_region" {
  description = "The primary AWS region"
  type        = string
  default     = "eu-west-1"
}

variable "vpc_id" {
  description = "The ID of the VPC"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for RDS subnet group"
  type        = list(string)
}

variable "security_group_id" {
  description = "Security group ID for RDS instance"
  type        = string
}

variable "db_name" {
  description = "Name of the database"
  type        = string
  default     = "drdb"
}

variable "db_username" {
  description = "Username for the database"
  type        = string
  default     = "dradmin"
}

variable "db_password" {
  description = "Password for the database (will be stored in SSM Parameter Store)"
  type        = string
  sensitive   = true
}

variable "db_instance_class" {
  description = "Instance class for the RDS instance"
  type        = string
  default     = "db.t3.small"
}

variable "db_engine" {
  description = "Database engine"
  type        = string
  default     = "mysql"
}

variable "db_engine_version" {
  description = "Database engine version"
  type        = string
  default     = "8.0"
}

variable "db_allocated_storage" {
  description = "Allocated storage for the database (in GB)"
  type        = number
  default     = 20
}

variable "db_storage_type" {
  description = "Storage type for the database"
  type        = string
  default     = "gp2"
}

variable "db_multi_az" {
  description = "Whether to enable Multi-AZ deployment"
  type        = bool
  default     = false
}

variable "db_backup_retention_period" {
  description = "Backup retention period in days"
  type        = number
  default     = 7
}

variable "db_backup_window" {
  description = "Preferred backup window"
  type        = string
  default     = "03:00-05:00"
}

variable "db_maintenance_window" {
  description = "Preferred maintenance window"
  type        = string
  default     = "sun:06:00-sun:08:00"
}

variable "db_skip_final_snapshot" {
  description = "Whether to skip the final snapshot when the database is deleted"
  type        = bool
  default     = false
}

variable "db_final_snapshot_identifier" {
  description = "Identifier for the final snapshot"
  type        = string
  default     = null
}

variable "is_read_replica" {
  description = "Whether this is a read replica in the DR region"
  type        = bool
  default     = false
}

variable "source_db_instance_identifier" {
  description = "Identifier of the source DB instance for read replica"
  type        = string
  default     = null
}

variable "enable_cross_region_backup" {
  description = "Whether to enable cross-region backup replication"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
}
