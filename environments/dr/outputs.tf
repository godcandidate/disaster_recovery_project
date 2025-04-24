# VPC and Networking Outputs
output "vpc_id" {
  description = "ID of the VPC in the DR region"
  value       = module.vpc.vpc_id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC in the DR region"
  value       = module.vpc.vpc_cidr
}

output "public_subnet_ids" {
  description = "IDs of public subnets in the DR region"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of private subnets in the DR region"
  value       = module.vpc.private_subnet_ids
}

# Security Group Outputs
output "ec2_security_group_id" {
  description = "ID of the EC2 security group in the DR region"
  value       = module.security_groups.ec2_security_group_id
}

output "rds_security_group_id" {
  description = "ID of the RDS security group in the DR region"
  value       = module.security_groups.rds_security_group_id
}

# IAM Outputs
output "ec2_role_arn" {
  description = "ARN of the EC2 IAM role in the DR region"
  value       = module.iam.ec2_role_arn
}

output "ec2_instance_profile_name" {
  description = "Name of the EC2 instance profile in the DR region"
  value       = module.iam.ec2_instance_profile_name
}

output "rds_role_arn" {
  description = "ARN of the RDS IAM role in the DR region"
  value       = module.iam.rds_role_arn
}

# EC2 Outputs - Pilot Light
output "launch_template_id" {
  description = "ID of the EC2 launch template in the DR region"
  value       = module.ec2.launch_template_id
}

output "autoscaling_group_id" {
  description = "ID of the Auto Scaling group in the DR region"
  value       = module.ec2.autoscaling_group_id
}

# Removed as we're using Auto Scaling Group for failover
# output "pilot_light_instance_id" {
#   description = "ID of the pilot light EC2 instance in the DR region"
#   value       = module.ec2.pilot_light_instance_id
# }

output "ami_id" {
  description = "AMI ID used for EC2 instances in the DR region"
  value       = module.ec2.ami_id
}

# RDS Outputs - Read Replica
output "read_replica_db_instance_id" {
  description = "ID of the read replica DB instance in the DR region"
  value       = module.rds.read_replica_db_instance_id
}

output "read_replica_db_instance_address" {
  description = "Address of the read replica DB instance in the DR region"
  value       = module.rds.read_replica_db_instance_address
}

output "read_replica_db_instance_endpoint" {
  description = "Endpoint of the read replica DB instance in the DR region"
  value       = module.rds.read_replica_db_instance_endpoint
}

# SSM Parameter Store Outputs removed as requested

# SSM Parameter Store Outputs removed as requested

output "region" {
  description = "DR region"
  value       = var.region
}

# DR Testing and Validation Outputs
output "lambda_function_arn" {
  description = "ARN of the DR failover Lambda function"
  value       = module.lambda.lambda_function_arn
}

output "lambda_function_name" {
  description = "Name of the DR failover Lambda function"
  value       = module.lambda.lambda_function_name
}

# output "api_gateway_id" {
#   description = "ID of the DR failover API Gateway"
#   value       = module.api_gateway.api_gateway_id
# }

# output "api_gateway_execution_arn" {
#   description = "Execution ARN of the DR failover API Gateway"
#   value       = module.api_gateway.api_gateway_execution_arn
# }

# output "api_gateway_invoke_url" {
#   description = "URL to invoke the DR failover API Gateway endpoint"
#   value       = module.api_gateway.api_gateway_invoke_url
# }

output "sns_topic_arn" {
  description = "ARN of the SNS topic for DR notifications"
  value       = aws_sns_topic.dr_notifications.arn
}

# Load Balancer Outputs
output "lb_arn" {
  description = "ARN of the load balancer in the DR region"
  value       = module.load_balancer.lb_arn
}

output "lb_dns_name" {
  description = "DNS name of the load balancer in the DR region"
  value       = module.load_balancer.lb_dns_name
}

output "target_group_arn" {
  description = "ARN of the target group in the DR region"
  value       = module.load_balancer.target_group_arn
}
