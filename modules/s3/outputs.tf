output "primary_bucket_id" {
  description = "ID of the primary S3 bucket"
  value       = aws_s3_bucket.primary.id
}

output "primary_bucket_arn" {
  description = "ARN of the primary S3 bucket"
  value       = aws_s3_bucket.primary.arn
}

output "primary_bucket_domain_name" {
  description = "Domain name of the primary S3 bucket"
  value       = aws_s3_bucket.primary.bucket_domain_name
}

output "dr_bucket_id" {
  description = "ID of the DR S3 bucket"
  value       = aws_s3_bucket.dr.id
}

output "dr_bucket_arn" {
  description = "ARN of the DR S3 bucket"
  value       = aws_s3_bucket.dr.arn
}

output "dr_bucket_domain_name" {
  description = "Domain name of the DR S3 bucket"
  value       = aws_s3_bucket.dr.bucket_domain_name
}

# Replication role moved to IAM module

output "primary_bucket_region" {
  description = "Region of the primary S3 bucket"
  value       = var.region
}

output "dr_bucket_region" {
  description = "Region of the DR S3 bucket"
  value       = var.dr_region
}
