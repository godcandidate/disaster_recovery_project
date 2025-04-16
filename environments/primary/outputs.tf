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

output "region" {
  description = "Primary region"
  value       = "eu-west-1"
}
