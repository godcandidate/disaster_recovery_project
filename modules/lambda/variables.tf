variable "environment" {
  description = "Environment (primary or dr)"
  type        = string
}

variable "region" {
  description = "The AWS region to deploy resources in"
  type        = string
}

variable "asg_name" {
  description = "Name of the Auto Scaling Group to update during failover"
  type        = string
}

variable "target_group_arn" {
  description = "ARN of the target group to attach instances to"
  type        = string
}

variable "api_gateway_execution_arn" {
  description = "Execution ARN of the API Gateway"
  type        = string
  default     = null
}

variable "sns_topic_arn" {
  description = "ARN of the SNS topic for notifications"
  type        = string
  default     = null
}

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
}
