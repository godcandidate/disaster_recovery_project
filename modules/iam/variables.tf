variable "environment" {
  description = "Environment (primary or dr)"
  type        = string
}

variable "primary_region" {
  description = "The primary AWS region"
  type        = string
  default     = "eu-west-1"
}

variable "dr_region" {
  description = "The DR AWS region"
  type        = string
  default     = "eu-west-2"
}

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
}
