variable "environment" {
  description = "Environment name (e.g., primary, dr)"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "step_function_arn" {
  description = "ARN of the Step Function to invoke"
  type        = string
  default     = null
}

variable "lambda_invoke_arn" {
  description = "Invoke ARN of the Lambda function to integrate with API Gateway"
  type        = string
}

variable "lambda_arn" {
  description = "ARN of the Lambda function"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
