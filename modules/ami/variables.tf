variable "environment" {
  description = "Environment (primary or dr)"
  type        = string
}

variable "region" {
  description = "The AWS region where the AMI will be created"
  type        = string
}

variable "source_instance_id" {
  description = "ID of the EC2 instance to create the AMI from"
  type        = string
}

variable "snapshot_without_reboot" {
  description = "Whether to create the AMI without rebooting the instance"
  type        = bool
  default     = true
}

variable "dr_region" {
  description = "The DR region to copy the AMI to (if any)"
  type        = string
  default     = ""
}

variable "target_account_id" {
  description = "AWS account ID to share the AMI with (if any)"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
}
