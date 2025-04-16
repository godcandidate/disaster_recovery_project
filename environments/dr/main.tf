provider "aws" {
  region = "eu-west-2"
}

terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
  
  # In a real environment, you would configure a backend for state storage
  # backend "s3" {
  #   bucket         = "terraform-state-dr-project"
  #   key            = "dr/terraform.tfstate"
  #   region         = "eu-west-2"
  #   dynamodb_table = "terraform-locks"
  #   encrypt        = true
  # }
}

locals {
  environment = "dr"
  region      = "eu-west-2"
  vpc_cidr    = "10.1.0.0/16"  # Non-overlapping with primary region
  
  availability_zones   = ["eu-west-2a", "eu-west-2b"]
  public_subnet_cidrs  = ["10.1.1.0/24", "10.1.2.0/24"]
  private_subnet_cidrs = ["10.1.3.0/24", "10.1.4.0/24"]
  
  tags = {
    Project     = "Disaster Recovery"
    Environment = local.environment
    ManagedBy   = "Terraform"
  }
}

# VPC Module
module "vpc" {
  source = "../../modules/vpc"
  
  region               = local.region
  vpc_cidr             = local.vpc_cidr
  vpc_name             = "dr-vpc-${local.environment}"
  environment          = local.environment
  public_subnet_cidrs  = local.public_subnet_cidrs
  private_subnet_cidrs = local.private_subnet_cidrs
  availability_zones   = local.availability_zones
  tags                 = local.tags
}

# IAM Module
module "iam" {
  source = "../../modules/iam"
  
  environment    = local.environment
  primary_region = "eu-west-1"
  dr_region      = "eu-west-2"
  tags           = local.tags
}

# Security Groups Module
module "security_groups" {
  source = "../../modules/security_groups"
  
  vpc_id           = module.vpc.vpc_id
  vpc_cidr         = local.vpc_cidr
  environment      = local.environment
  allowed_ssh_cidrs = ["10.1.0.0/8"] # Restrict SSH access in production
  db_port          = 3306 # MySQL default port
  tags             = local.tags
}
