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

# Fallback to Amazon Linux AMI if the custom AMI is not available
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Custom AMI data source for the copied AMI from primary region
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

# EC2 Module - DR Region (Auto Scaling Group only)
module "ec2" {
  source = "../../modules/ec2"
  
  environment          = var.environment
  region               = var.region
  vpc_id               = module.vpc.vpc_id
  subnet_ids           = module.vpc.public_subnet_ids
  security_group_id    = module.security_groups.ec2_security_group_id
  instance_type        = var.instance_type
  key_name             = var.key_name
  instance_profile_name = module.iam.ec2_instance_profile_name
  min_size             = 0
  max_size             = 2
  desired_capacity     = 0
  is_pilot_light       = false
  # Use the copied AMI from primary region, with fallback to Amazon Linux AMI
  ami_id               = try(data.aws_ami.dr_ami.id, data.aws_ami.amazon_linux.id)
  
  # User data script for EC2 instances
  user_data = templatefile("../../modules/templates/dr_userdata.tpl", {
    REGION           = var.region
    DB_HOST_PARAM    = module.ssm.db_host_parameter_name
    DB_PORT_PARAM    = module.ssm.db_port_parameter_name
    DB_NAME_PARAM    = module.ssm.db_name_parameter_name
    DB_USER_PARAM    = module.ssm.db_username_parameter_name
    DB_PASSWORD_PARAM = module.ssm.db_password_parameter_name
    S3_BUCKET_ID_PARAM = module.s3.dr_bucket_id
    S3_BUCKET_REGION_PARAM = module.s3.dr_bucket_region
  })
  
  tags = local.tags
}

# Load Balancer Module - DR Region
module "load_balancer" {
  source = "../../modules/load_balancer"
  
  environment      = var.environment
  vpc_id           = module.vpc.vpc_id
  subnet_ids       = module.vpc.public_subnet_ids
  security_group_id = module.security_groups.lb_security_group_id
  
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
  is_read_replica        = true # Changed to true to create a read replica
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

# SNS Topic for DR notifications
resource "aws_sns_topic" "dr_notifications" {
  name = "dr-notifications-${var.environment}"
  
  tags = local.tags
}

# SNS Topic Subscription for email notifications
resource "aws_sns_topic_subscription" "dr_email_subscription" {
  topic_arn = aws_sns_topic.dr_notifications.arn
  protocol  = "email"
  endpoint  = "godcandidate101@gmail.com"
}



# Lambda Module for Failover
module "lambda" {
  source = "../../modules/lambda"
  
  environment            = var.environment
  region                 = var.region
  asg_name               = module.ec2.autoscaling_group_name
  target_group_arn       = module.load_balancer.target_group_arn
  sns_topic_arn          = aws_sns_topic.dr_notifications.arn
  
  tags = local.tags
}

# API Gateway Module
module "api_gateway" {
  source = "../../modules/api_gateway"
  
  environment      = var.environment
  region           = var.region
  step_function_arn = module.lambda.lambda_function_arn
  lambda_invoke_arn = module.lambda.lambda_invoke_arn
  lambda_arn       = module.lambda.lambda_function_arn
  
  tags = local.tags
}

# Lambda API Connector Module
# This connects the Lambda function to the API Gateway after both are created
module "lambda_api_connector" {
  source = "../../modules/lambda_api_connector"
  
  environment             = var.environment
  lambda_function_name    = module.lambda.lambda_function_name
  api_gateway_execution_arn = module.api_gateway.api_gateway_execution_arn
  
  tags = local.tags
}

# SSM Module - DR Region
module "ssm" {
  source = "../../modules/ssm"
  
  environment       = var.environment
  region            = var.region
  db_name           = var.db_name
  db_username       = var.db_username
  db_password       = var.db_password
  db_endpoint       = module.rds.read_replica_db_instance_address
  db_port           = "3306"
  s3_bucket_id      = module.s3.primary_bucket_id
  s3_bucket_region  = module.s3.primary_bucket_region
  
  tags = local.tags
  
  depends_on = [module.s3]
}
