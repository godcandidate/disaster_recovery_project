output "lambda_function_arn" {
  description = "ARN of the Lambda function"
  value       = aws_lambda_function.function.arn
}

output "lambda_function_name" {
  description = "Name of the Lambda function"
  value       = aws_lambda_function.function.function_name
}

output "lambda_function_invoke_arn" {
  description = "Invoke ARN of the Lambda function"
  value       = aws_lambda_function.function.invoke_arn
}

# Lambda role moved to IAM module

output "lambda_security_group_id" {
  description = "ID of the security group for the Lambda function"
  value       = aws_security_group.lambda_sg.id
}

output "lambda_enabled" {
  description = "Whether the Lambda function is enabled"
  value       = var.enabled
}
