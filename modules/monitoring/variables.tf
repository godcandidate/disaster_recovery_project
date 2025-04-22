variable "environment" {
  description = "Environment name (e.g., primary, dr)"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "asg_name" {
  description = "Name of the Auto Scaling Group to monitor"
  type        = string
}

variable "rds_primary_id" {
  description = "ID of the primary RDS instance"
  type        = string
}

variable "rds_read_replica_id" {
  description = "ID of the RDS read replica"
  type        = string
}

variable "sns_topic_arn" {
  description = "ARN of the SNS topic for alarm notifications"
  type        = string
  default     = ""
}

variable "api_gateway_execution_arn" {
  description = "Execution ARN of the API Gateway"
  type        = string
  default     = ""
}

variable "api_gateway_invoke_url" {
  description = "URL to invoke the API Gateway endpoint"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
