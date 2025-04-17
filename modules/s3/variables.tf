variable "environment" {
  description = "Environment name (e.g., primary, dr)"
  type        = string
}

variable "region" {
  description = "AWS region for the primary bucket"
  type        = string
}

variable "dr_region" {
  description = "AWS region for the DR bucket"
  type        = string
}

variable "bucket_name" {
  description = "Base name for the S3 buckets"
  type        = string
}

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
}
