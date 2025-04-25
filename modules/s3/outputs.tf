output "primary_bucket_id" {
  description = "ID of the primary S3 bucket"
  value       = "dr-primary-${var.bucket_name}-${var.region}"
}

output "primary_bucket_arn" {
  description = "ARN of the primary S3 bucket"
  value       = "arn:aws:s3:::dr-primary-${var.bucket_name}-${var.region}"
}

output "primary_bucket_domain_name" {
  description = "Domain name of the primary S3 bucket"
  value       = "dr-primary-${var.bucket_name}-${var.region}.s3.amazonaws.com"
}

output "dr_bucket_id" {
  description = "ID of the DR S3 bucket"
  value       = "dr-primary-${var.bucket_name}-${var.dr_region}"
}

output "dr_bucket_arn" {
  description = "ARN of the DR S3 bucket"
  value       = "arn:aws:s3:::dr-primary-${var.bucket_name}-${var.dr_region}"
}

output "dr_bucket_domain_name" {
  description = "Domain name of the DR S3 bucket"
  value       = "dr-primary-${var.bucket_name}-${var.dr_region}.s3.amazonaws.com"
}

output "primary_bucket_region" {
  description = "Region of the primary S3 bucket"
  value       = var.region
}

output "dr_bucket_region" {
  description = "Region of the DR S3 bucket"
  value       = var.dr_region
}

# Replication role moved to IAM module
