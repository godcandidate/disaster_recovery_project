variable "environment" {
  description = "Environment name"
  type        = string
  default     = "primary"
}

variable "region" {
  description = "AWS region for the primary environment"
  type        = string
  default     = "eu-west-1"
}

variable "dr_region" {
  description = "AWS region for the DR environment"
  type        = string
  default     = "eu-west-2"
}


variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones to use"
  type        = list(string)
  default     = ["eu-west-1a", "eu-west-1b"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for the public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for the private subnets"
  type        = list(string)
  default     = ["10.0.3.0/24", "10.0.4.0/24"]
}

# EC2 Configuration
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "key_name" {
  description = "Name of the SSH key pair"
  type        = string
  default     = "labs_key"
}

# RDS Configuration
variable "db_name" {
  description = "Name of the database"
  type        = string
  default     = "todoDB"
}

variable "db_username" {
  description = "Username for the database"
  type        = string
  default     = "dradmin"
}

variable "db_password" {
  description = "Password for the database"
  type        = string
  default     = "ChangeMe123!" # In production, use a secure method to manage secrets
  sensitive   = true
}

variable "db_instance_class" {
  description = "Instance class for the RDS instance"
  type        = string
  default     = "db.t3.small"
}

variable "db_engine" {
  description = "Database engine"
  type        = string
  default     = "mysql"
}

variable "db_engine_version" {
  description = "Database engine version"
  type        = string
  default     = "8.0"
}

variable "db_allocated_storage" {
  description = "Allocated storage for the database (in GB)"
  type        = number
  default     = 10
}

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {
    Project     = "Disaster Recovery"
    ManagedBy   = "Terraform"
  }
}
