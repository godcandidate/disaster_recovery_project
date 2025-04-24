variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dr"
}

variable "region" {
  description = "AWS region for the DR environment"
  type        = string
  default     = "us-east-1"
}

variable "primary_region" {
  description = "AWS region for the primary environment"
  type        = string
  default     = "eu-west-1"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.1.0.0/16" # Non-overlapping with primary region
}

variable "availability_zones" {
  description = "List of availability zones to use"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for the public subnets"
  type        = list(string)
  default     = ["10.1.1.0/24", "10.1.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for the private subnets"
  type        = list(string)
  default     = ["10.1.3.0/24", "10.1.4.0/24"]
}

# EC2 Configuration
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "Name of the SSH key pair"
  type        = string
  default     = "labs"
}

# RDS Configuration
variable "db_name" {
  description = "Name of the database"
  type        = string
  default     = "drdb"
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
  default     = 20
}

variable "db_multi_az" {
  description = "Whether to enable Multi-AZ deployment"
  type        = bool
  default     = false
}

# Primary region RDS instance identifier (for read replica)
variable "primary_db_instance_id" {
  description = "ID of the primary DB instance for reference in DR region"
  type        = string
  default     = "dr-db-primary"
}

variable "aws_access_key" {
  description = "AWS Access Key for S3 access"
  type        = string
  sensitive   = true
  default     = ""
}

variable "aws_secret_key" {
  description = "AWS Secret Key for S3 access"
  type        = string
  sensitive   = true
  default     = ""
}

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {
    Project     = "Disaster Recovery"
    ManagedBy   = "Terraform"
  }
}