output "lambda_function_name" {
  description = "Name of the Lambda function"
  value       = aws_lambda_function.dr_failover.function_name
}

output "lambda_function_arn" {
  description = "ARN of the Lambda function"
  value       = aws_lambda_function.dr_failover.arn
}

output "lambda_invoke_arn" {
  description = "Invoke ARN of the Lambda function for API Gateway"
  value       = aws_lambda_function.dr_failover.invoke_arn
}

output "lambda_role_arn" {
  description = "ARN of the IAM role for the Lambda function"
  value       = aws_iam_role.lambda_role.arn
}
