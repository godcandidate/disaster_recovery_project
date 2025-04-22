# VPC and Networking Outputs
output "vpc_id" {
  description = "ID of the VPC in the primary region"
  value       = module.vpc.vpc_id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC in the primary region"
  value       = module.vpc.vpc_cidr
}

output "public_subnet_ids" {
  description = "IDs of public subnets in the primary region"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of private subnets in the primary region"
  value       = module.vpc.private_subnet_ids
}

# Security Group Outputs
output "ec2_security_group_id" {
  description = "ID of the EC2 security group in the primary region"
  value       = module.security_groups.ec2_security_group_id
}

output "rds_security_group_id" {
  description = "ID of the RDS security group in the primary region"
  value       = module.security_groups.rds_security_group_id
}

output "lambda_security_group_id" {
  description = "ID of the Lambda security group in the primary region"
  value       = module.security_groups.lambda_security_group_id
}

# IAM Outputs
output "ec2_role_arn" {
  description = "ARN of the EC2 IAM role in the primary region"
  value       = module.iam.ec2_role_arn
}

output "ec2_instance_profile_name" {
  description = "Name of the EC2 instance profile in the primary region"
  value       = module.iam.ec2_instance_profile_name
}

output "rds_role_arn" {
  description = "ARN of the RDS IAM role in the primary region"
  value       = module.iam.rds_role_arn
}

output "lambda_role_arn" {
  description = "ARN of the Lambda IAM role in the primary region"
  value       = module.iam.lambda_role_arn
}

# Region Output
output "region" {
  description = "AWS region for the primary environment"
  value       = var.region
}

# S3 Outputs
output "s3_primary_bucket_id" {
  description = "ID of the primary S3 bucket"
  value       = module.s3.primary_bucket_id
}

output "s3_dr_bucket_id" {
  description = "ID of the DR S3 bucket"
  value       = module.s3.dr_bucket_id
}

# EC2 Outputs
output "launch_template_id" {
  description = "ID of the EC2 launch template in the primary region"
  value       = module.ec2.launch_template_id
}

output "autoscaling_group_id" {
  description = "ID of the Auto Scaling group in the primary region"
  value       = module.ec2.autoscaling_group_id
}

output "autoscaling_group_name" {
  description = "Name of the Auto Scaling group in the primary region"
  value       = module.ec2.autoscaling_group_name
}

output "ami_id" {
  description = "AMI ID used for EC2 instances in the primary region"
  value       = module.ec2.ami_id
}

# Monitoring Outputs
output "ec2_system_check_alarm_arn" {
  description = "ARN of the EC2 system check alarm in the primary region"
  value       = module.monitoring.ec2_system_check_alarm_arn
}

output "ec2_instance_check_alarm_arn" {
  description = "ARN of the EC2 instance check alarm in the primary region"
  value       = module.monitoring.ec2_instance_check_alarm_arn
}

output "rds_replica_lag_alarm_arn" {
  description = "ARN of the RDS replica lag alarm in the primary region"
  value       = module.monitoring.rds_replica_lag_alarm_arn
}

output "composite_alarm_arn" {
  description = "ARN of the composite alarm in the primary region"
  value       = module.monitoring.composite_alarm_arn
}

output "sns_topic_arn" {
  description = "ARN of the SNS topic for alarm notifications in the primary region"
  value       = module.monitoring.sns_topic_arn
}

# RDS Outputs
output "primary_db_instance_id" {
  description = "ID of the primary DB instance"
  value       = module.rds.primary_db_instance_id
}

output "primary_db_instance_address" {
  description = "Address of the primary DB instance"
  value       = module.rds.primary_db_instance_address
}

output "primary_db_instance_endpoint" {
  description = "Endpoint of the primary DB instance"
  value       = module.rds.primary_db_instance_endpoint
}

output "primary_db_instance_arn" {
  description = "ARN of the primary DB instance"
  value       = module.rds.primary_db_instance_arn
}

output "backup_replication_kms_key_arn" {
  description = "ARN of the KMS key used for backup replication"
  value       = module.rds.backup_replication_kms_key_arn
}

# SSM Parameter Store Outputs removed as requested
