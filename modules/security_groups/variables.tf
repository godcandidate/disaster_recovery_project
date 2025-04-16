variable "vpc_id" {
  description = "The ID of the VPC"
  type        = string
}

variable "environment" {
  description = "Environment (primary or dr)"
  type        = string
}

variable "vpc_cidr" {
  description = "The CIDR block of the VPC"
  type        = string
}

variable "allowed_ssh_cidrs" {
  description = "List of CIDR blocks allowed to SSH to EC2 instances"
  type        = list(string)
  default     = ["0.0.0.0/0"] # This should be restricted in production
}

variable "db_port" {
  description = "The port for database connections"
  type        = number
  default     = 3306 # Default for MySQL
}

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
}
