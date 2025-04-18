provider "aws" {
  region = var.region
}

# Provider for Primary region
provider "aws" {
  alias  = "primary"
  region = var.primary_region
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
  tags = merge(
    var.tags,
    {
      Environment = var.environment
    }
  )
}

# VPC Module
module "vpc" {
  source = "../../modules/vpc"
  
  region               = var.region
  vpc_cidr             = var.vpc_cidr
  vpc_name             = "dr-vpc-${var.environment}"
  environment          = var.environment
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones   = var.availability_zones
  tags                 = local.tags
}



# IAM Module
module "iam" {
  source = "../../modules/iam"
  
  environment    = var.environment
  primary_region = var.primary_region
  dr_region      = var.region
  tags           = local.tags
}

# Security Groups Module
module "security_groups" {
  source = "../../modules/security_groups"
  
  vpc_id           = module.vpc.vpc_id
  vpc_cidr         = var.vpc_cidr
  environment      = var.environment
  allowed_ssh_cidrs = ["10.1.0.0/8"] # Restrict SSH access in production
  db_port          = 3306 # MySQL default port
  tags             = local.tags
}

# Data source to get the AMI created in the primary region
data "aws_ami" "dr_ami" {
  most_recent = true
  owners      = ["self"]

  filter {
    name   = "name"
    values = ["dr-ami-primary-*"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

# EC2 Module - DR Region (Pilot Light)
module "ec2" {
  source = "../../modules/ec2"
  
  environment          = var.environment
  region               = var.region
  vpc_id               = module.vpc.vpc_id
  subnet_ids           = module.vpc.private_subnet_ids
  security_group_id    = module.security_groups.ec2_security_group_id
  instance_type        = var.instance_type
  key_name             = var.key_name
  instance_profile_name = module.iam.ec2_instance_profile_name
  min_size             = 0
  max_size             = 2
  desired_capacity     = 0
  is_pilot_light       = true
  ami_id               = data.aws_ami.dr_ami.id # Use the AMI created in the primary region
  
  # User data script for EC2 instances
  # Minimal user data since most setup is already in the AMI
  user_data = templatefile("../../modules/templates/dr_userdata.tpl", {
    environment = var.environment
    region      = var.region
    DB_NAME     = var.db_name
    DB_USER     = var.db_username
    DB_PASSWORD = var.db_password
    DB_HOST     = module.rds.read_replica_db_instance_address
    EC2_IP      = "dummy" # This will be replaced at runtime by the script
  })
  
  tags = local.tags
}

# RDS Module - DR Region (Read Replica)
module "rds" {
  source = "../../modules/rds"
  
  environment            = var.environment
  region                 = var.region
  primary_region         = var.primary_region
  vpc_id                 = module.vpc.vpc_id
  subnet_ids             = module.vpc.private_subnet_ids
  security_group_id      = module.security_groups.rds_security_group_id
  db_name                = var.db_name
  db_username            = var.db_username
  db_password            = var.db_password
  db_instance_class      = var.db_instance_class
  db_engine              = var.db_engine
  db_engine_version      = var.db_engine_version
  db_allocated_storage   = var.db_allocated_storage
  db_multi_az            = var.db_multi_az # Single AZ for read replica is sufficient
  db_backup_retention_period = 1
  enable_cross_region_backup = false
  is_read_replica        = true
  source_db_instance_identifier = var.primary_db_instance_id
  
  tags = local.tags
}

# S3 Module - DR Region with access to primary region buckets
module "s3" {
  source = "../../modules/s3"
  
  environment = var.environment
  region      = var.region
  dr_region   = var.primary_region  # In DR environment, the primary region is the DR region for S3
  bucket_name = "storage-${var.environment}"
  replication_role_arn = module.iam.s3_replication_role_arn
  
  providers = {
    aws    = aws
    aws.dr = aws.primary
  }
  
  tags = local.tags
}

# Lambda Module - DR Region (Disabled)
module "lambda" {
  source = "../../modules/lambda"
  
  environment = var.environment
  region      = var.region
  function_name = "tasks-due-tomorrow"
  s3_bucket_id = module.s3.primary_bucket_id
  vpc_id      = module.vpc.vpc_id
  subnet_ids  = module.vpc.private_subnet_ids
  db_host     = module.rds.read_replica_db_instance_address
  db_username = var.db_username
  db_password = var.db_password
  db_name     = var.db_name
  enabled     = false  # Disabled in DR region
  build_locally = false  # Use the package from the primary region
  lambda_role_arn = module.iam.lambda_role_arn
  
  tags = local.tags
  
  # Ensure S3 bucket is created before Lambda
  depends_on = [module.s3]
}
