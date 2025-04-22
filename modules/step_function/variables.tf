variable "environment" {
  description = "Environment name (e.g., primary, dr)"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "rds_read_replica_id" {
  description = "ID of the RDS read replica to promote during failover"
  type        = string
}

variable "asg_name" {
  description = "Name of the Auto Scaling Group to scale during failover"
  type        = string
}

variable "sns_topic_arn" {
  description = "ARN of the SNS topic for notifications"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
