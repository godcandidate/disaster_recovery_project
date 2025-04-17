output "ec2_role_arn" {
  description = "ARN of the EC2 IAM role for disaster recovery"
  value       = aws_iam_role.ec2_dr_role.arn
}

output "ec2_instance_profile_name" {
  description = "Name of the EC2 instance profile for disaster recovery"
  value       = aws_iam_instance_profile.ec2_dr_profile.name
}

output "rds_role_arn" {
  description = "ARN of the RDS IAM role for disaster recovery"
  value       = aws_iam_role.rds_dr_role.arn
}

output "lambda_role_arn" {
  description = "ARN of the Lambda IAM role for disaster recovery"
  value       = aws_iam_role.lambda_dr_role.arn
}

output "cross_region_assume_role_policy_arn" {
  description = "ARN of the cross-region assume role policy"
  value       = aws_iam_policy.cross_region_assume_role.arn
}

output "s3_replication_role_arn" {
  description = "ARN of the S3 replication IAM role"
  value       = aws_iam_role.s3_replication_role.arn
}
