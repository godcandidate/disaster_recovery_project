variable "lambda_function_name" {
  description = "Name of the Lambda function to connect to API Gateway"
  type        = string
}

variable "api_gateway_execution_arn" {
  description = "Execution ARN of the API Gateway"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., primary, dr)"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
