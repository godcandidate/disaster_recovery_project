variable "environment" {
  description = "Environment name"
  type        = string
  default     = "global"
}

variable "region" {
  description = "AWS region for global resources"
  type        = string
  default     = "us-east-1"  # Global Accelerator is a global service but we need a region for the provider
}

variable "primary_region" {
  description = "AWS region for primary environment"
  type        = string
  default     = "eu-west-1"  # Default primary region
}

variable "dr_region" {
  description = "AWS region for DR environment"
  type        = string
  default     = "us-east-1"  # Default DR region
}

variable "primary_traffic_dial_percentage" {
  description = "Percentage of traffic to route to the primary region (0-100)"
  type        = number
  default     = 100  # By default, send all traffic to primary region
}

variable "dr_traffic_dial_percentage" {
  description = "Percentage of traffic to route to the DR region (0-100)"
  type        = number
  default     = 0    # By default, no traffic to DR region
}


variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
