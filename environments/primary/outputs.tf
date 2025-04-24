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

# Lambda outputs removed as requested

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

# Lambda outputs removed as requested

# Region Output
output "region" {
  description = "AWS region for the primary environment"
  value       = var.region
}

# S3 outputs removed as requested

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

# Monitoring outputs removed as requested

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

# SSM Parameter Store Outputs
output "db_host_parameter_name" {
  description = "Name of the SSM parameter for database host"
  value       = module.ssm.db_host_parameter_name
}

output "db_port_parameter_name" {
  description = "Name of the SSM parameter for database port"
  value       = module.ssm.db_port_parameter_name
}

output "db_name_parameter_name" {
  description = "Name of the SSM parameter for database name"
  value       = module.ssm.db_name_parameter_name
}

output "db_username_parameter_name" {
  description = "Name of the SSM parameter for database username"
  value       = module.ssm.db_username_parameter_name
}

output "db_password_parameter_name" {
  description = "Name of the SSM parameter for database password"
  value       = module.ssm.db_password_parameter_name
}

# Load Balancer Outputs
output "lb_arn" {
  description = "ARN of the load balancer in the primary region"
  value       = module.load_balancer.lb_arn
}

output "lb_dns_name" {
  description = "DNS name of the load balancer in the primary region"
  value       = module.load_balancer.lb_dns_name
}

output "target_group_arn" {
  description = "ARN of the target group in the primary region"
  value       = module.load_balancer.target_group_arn
}
