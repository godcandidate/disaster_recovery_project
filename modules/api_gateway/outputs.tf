output "api_gateway_id" {
  description = "ID of the API Gateway REST API"
  value       = aws_api_gateway_rest_api.dr_failover.id
}

output "api_gateway_root_resource_id" {
  description = "ID of the API Gateway root resource"
  value       = aws_api_gateway_rest_api.dr_failover.root_resource_id
}

output "api_gateway_execution_arn" {
  description = "Execution ARN of the API Gateway"
  value       = aws_api_gateway_rest_api.dr_failover.execution_arn
}

output "api_gateway_invoke_url" {
  description = "URL to invoke the API Gateway endpoint"
  value       = "${aws_api_gateway_stage.dr_failover.invoke_url}/failover"
}

output "api_gateway_role_arn" {
  description = "ARN of the IAM role for API Gateway to invoke Step Function"
  value       = aws_iam_role.api_gateway_step_function.arn
}
