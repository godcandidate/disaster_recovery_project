variable "environment" {
  description = "Environment (primary or dr)"
  type        = string
}

variable "region" {
  description = "The AWS region to deploy resources in"
  type        = string
}

variable "vpc_id" {
  description = "The ID of the VPC"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for EC2 instances"
  type        = list(string)
}

variable "security_group_id" {
  description = "Security group ID for EC2 instances"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "Name of the SSH key pair"
  type        = string
  default     = null
}

variable "instance_profile_name" {
  description = "Name of the IAM instance profile"
  type        = string
}

variable "ami_id" {
  description = "AMI ID for EC2 instances (if not using ami_filter)"
  type        = string
  default     = null
}

variable "ami_filter" {
  description = "Filter to find the AMI"
  type        = map(string)
  default     = {
    name                = "amzn2-ami-hvm-*-x86_64-gp2"
    virtualization-type = "hvm"
    root-device-type    = "ebs"
  }
}

variable "ami_owners" {
  description = "List of AMI owners to limit search"
  type        = list(string)
  default     = ["amazon"]
}

variable "user_data" {
  description = "User data script for EC2 instances"
  type        = string
  default     = ""
}

variable "min_size" {
  description = "Minimum size of the Auto Scaling group"
  type        = number
  default     = 0
}

variable "max_size" {
  description = "Maximum size of the Auto Scaling group"
  type        = number
  default     = 1
}

variable "desired_capacity" {
  description = "Desired capacity of the Auto Scaling group"
  type        = number
  default     = 0
}

variable "is_pilot_light" {
  description = "Whether this is a pilot light setup (instances are stopped in DR)"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
}
