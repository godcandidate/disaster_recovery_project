variable "environment" {
  description = "Environment name (e.g., primary, dr)"
  type        = string
}

variable "region" {
  description = "AWS region for the Lambda function"
  type        = string
}

variable "function_name" {
  description = "Name of the Lambda function"
  type        = string
  default     = "tasks-due-tomorrow"
}

variable "s3_bucket_id" {
  description = "ID of the S3 bucket to store Lambda function code"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC where Lambda function will be deployed"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs where Lambda function will be deployed"
  type        = list(string)
}

variable "db_host" {
  description = "RDS instance endpoint"
  type        = string
}

variable "db_username" {
  description = "RDS instance username"
  type        = string
}

variable "db_password" {
  description = "RDS instance password"
  type        = string
  sensitive   = true
}

variable "db_name" {
  description = "RDS database name"
  type        = string
}

variable "enabled" {
  description = "Whether the Lambda function is enabled (true for primary, false for DR)"
  type        = bool
  default     = true
}

variable "build_locally" {
  description = "Whether to build the Lambda package locally"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
}

variable "lambda_role_arn" {
  description = "ARN of the IAM role for Lambda function"
  type        = string
}
