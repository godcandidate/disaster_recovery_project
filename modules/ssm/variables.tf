variable "environment" {
  description = "Environment (primary or dr)"
  type        = string
}

variable "region" {
  description = "The AWS region to deploy resources in"
  type        = string
}

variable "db_name" {
  description = "Name of the database"
  type        = string
}

variable "db_username" {
  description = "Username for the database"
  type        = string
}

variable "db_password" {
  description = "Password for the database"
  type        = string
  sensitive   = true
}

variable "db_endpoint" {
  description = "Endpoint of the database"
  type        = string
}

variable "db_port" {
  description = "Port of the database"
  type        = string
  default     = "3306"
}

variable "kms_key_id" {
  description = "KMS key ID for parameter encryption"
  type        = string
  default     = null
}

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
}

variable "s3_bucket_id" {
  description = "S3 bucket ID for the application"
  type        = string
  default     = ""
}

variable "s3_bucket_region" {
  description = "Region of the S3 bucket"
  type        = string
  default     = ""
}
