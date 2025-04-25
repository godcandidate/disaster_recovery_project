output "kms_key_id" {
  description = "ID of the KMS key used for SSM parameters"
  value       = var.kms_key_id != null ? var.kms_key_id : (var.kms_key_id == null ? aws_kms_key.ssm[0].key_id : null)
}

output "kms_key_arn" {
  description = "ARN of the KMS key used for SSM parameters"
  value       = var.kms_key_id != null ? var.kms_key_id : (var.kms_key_id == null ? aws_kms_key.ssm[0].arn : null)
}

output "parameter_prefix" {
  description = "Prefix for SSM parameters"
  value       = local.parameter_prefix
}

output "db_host_parameter_name" {
  description = "Name of the SSM parameter for database host"
  value       = aws_ssm_parameter.db_host.name
}

output "db_port_parameter_name" {
  description = "Name of the SSM parameter for database port"
  value       = aws_ssm_parameter.db_port.name
}

output "db_name_parameter_name" {
  description = "Name of the SSM parameter for database name"
  value       = aws_ssm_parameter.db_name.name
}

output "db_username_parameter_name" {
  description = "Name of the SSM parameter for database username"
  value       = aws_ssm_parameter.db_username.name
}

output "db_password_parameter_name" {
  description = "Name of the SSM parameter for database password"
  value       = aws_ssm_parameter.db_password.name
}

output "db_connection_string_mysql_parameter_name" {
  description = "Name of the SSM parameter for MySQL connection string"
  value       = aws_ssm_parameter.db_connection_string_mysql.name
}

output "db_connection_string_jdbc_parameter_name" {
  description = "Name of the SSM parameter for JDBC connection string"
  value       = aws_ssm_parameter.db_connection_string_jdbc.name
}

# S3 bucket parameter outputs
output "s3_bucket_id_parameter_name" {
  description = "Name of the SSM parameter for S3 bucket ID"
  value       = aws_ssm_parameter.s3_bucket_id.name
}

output "s3_bucket_region_parameter_name" {
  description = "Name of the SSM parameter for S3 bucket region"
  value       = aws_ssm_parameter.s3_bucket_region.name
}
