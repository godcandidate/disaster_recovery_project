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
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
