provider "aws" {
  region = var.region
}

# Provider for DR region
provider "aws" {
  alias  = "dr"
  region = var.dr_region
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
  #   key            = "primary/terraform.tfstate"
  #   region         = "eu-west-1"
  #   dynamodb_table = "terraform-locks"
  #   encrypt        = true
  # }
}

# This section has been muted as requested to focus on core resources

locals {
  tags = merge(
    var.tags,
    {
      Environment = var.environment
    }
  )
}

# Random string for unique S3 bucket names
resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
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

# IAM Module - Primary Region
module "iam" {
  source = "../../modules/iam"
  
  environment    = var.environment
  primary_region = var.region
  dr_region      = var.dr_region
  
  tags = local.tags
}

# S3 Module - Primary Region
module "s3" {
  source = "../../modules/s3"
  
  environment = var.environment
  region      = var.region
  dr_region   = var.dr_region
  bucket_name = "image-gallery-${var.environment}-${random_string.suffix.result}"
  replication_role_arn = module.iam.s3_replication_role_arn
  
  providers = {
    aws = aws
    aws.dr = aws.dr
  }
  
  tags = local.tags
}

# SSM Parameter Store Module - Primary Region
module "ssm" {
  source = "../../modules/ssm"
  
  environment     = var.environment
  region          = var.region
  db_name         = var.db_name
  db_username     = var.db_username
  db_password     = var.db_password
  db_endpoint     = module.rds.primary_db_instance_address
  db_port         = "3306"
  s3_bucket_id    = module.s3.primary_bucket_id
  s3_bucket_region = module.s3.primary_bucket_region
  
  tags = local.tags
  
  depends_on = [module.s3]
}

# Security Groups Module
module "security_groups" {
  source = "../../modules/security_groups"
  
  vpc_id           = module.vpc.vpc_id
  vpc_cidr         = var.vpc_cidr
  environment      = var.environment
  allowed_ssh_cidrs = ["10.0.0.0/8"] # Restrict SSH access in production
  db_port          = 3306 # MySQL default port
  tags             = local.tags
}

# AMI Builder Instance - For creating a pre-configured AMI
resource "aws_instance" "ami_builder" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  subnet_id              = module.vpc.public_subnet_ids[0] # Use public subnet for easier access
  vpc_security_group_ids = [module.security_groups.ec2_security_group_id]
  key_name               = var.key_name
  iam_instance_profile   = module.iam.ec2_instance_profile_name
  associate_public_ip_address = true
  
  user_data = templatefile("../../modules/templates/primary_userdata.tpl", {
    REGION           = var.region
    DB_HOST_PARAM    = module.ssm.db_host_parameter_name
    DB_PORT_PARAM    = module.ssm.db_port_parameter_name
    DB_NAME_PARAM    = module.ssm.db_name_parameter_name
    DB_USER_PARAM    = module.ssm.db_username_parameter_name
    DB_PASSWORD_PARAM = module.ssm.db_password_parameter_name
    EC2_IP           = "dummy" # Will be replaced at runtime by the script
    AWS_ACCESS_KEY   = var.aws_access_key
    AWS_SECRET_KEY   = var.aws_secret_key
    S3_BUCKET_ID_PARAM = module.ssm.s3_bucket_id_parameter_name
    S3_BUCKET_REGION_PARAM = module.ssm.s3_bucket_region_parameter_name
  })
  
  tags = merge(
    local.tags,
    {
      Name    = "dr-ami-builder-${var.environment}"
      Purpose = "AMI Creation"
    }
  )
  
  # Wait for instance to be ready before creating AMI
  provisioner "local-exec" {
    command = <<-EOT
      aws ec2 wait instance-status-ok --instance-ids ${self.id} --region ${var.region}
      sleep 60  # Additional time for user data script to complete
    EOT
  }
}

# Register AMI builder instance with the ALB target group
resource "aws_lb_target_group_attachment" "ami_builder" {
  target_group_arn = module.load_balancer.target_group_arn
  target_id        = aws_instance.ami_builder.id
  port             = 80
}

# Data source for Amazon Linux AMI
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

# AMI Creation from the builder instance
module "ami" {
  source = "../../modules/ami"
  
  environment         = var.environment
  region              = var.region
  source_instance_id  = aws_instance.ami_builder.id
  snapshot_without_reboot = true
  dr_region           = var.dr_region # Enable copying to DR region
  
  providers = {
    aws    = aws
    aws.dr = aws.dr
  }
  
  tags = local.tags
  
  # Only create the AMI after the builder instance is fully provisioned
  depends_on = [aws_instance.ami_builder]
}

# EC2 Module - Primary Region
module "ec2" {
  source = "../../modules/ec2"
  
  environment         = var.environment
  region              = var.region
  vpc_id              = module.vpc.vpc_id
  subnet_ids          = module.vpc.public_subnet_ids
  security_group_id    = module.security_groups.ec2_security_group_id
  instance_type        = var.instance_type
  key_name             = var.key_name
  instance_profile_name = module.iam.ec2_instance_profile_name
  ami_id               = module.ami.ami_id  # Use the AMI created by the AMI module
  min_size             = 0
  max_size             = 2
  desired_capacity     = 0
  is_pilot_light       = false
  target_group_arns    = [module.load_balancer.target_group_arn]
  
  # User data script for EC2 instances - using SSM parameters instead of direct credentials
  user_data = templatefile("../../modules/templates/primary_userdata.tpl", {
    REGION           = var.region
    DB_HOST_PARAM    = module.ssm.db_host_parameter_name
    DB_PORT_PARAM    = module.ssm.db_port_parameter_name
    DB_NAME_PARAM    = module.ssm.db_name_parameter_name
    DB_USER_PARAM    = module.ssm.db_username_parameter_name
    DB_PASSWORD_PARAM = module.ssm.db_password_parameter_name
    EC2_IP           = "dummy" # Will be replaced at runtime by the script
    AWS_ACCESS_KEY   = var.aws_access_key
    AWS_SECRET_KEY   = var.aws_secret_key
    S3_BUCKET_ID_PARAM = module.ssm.s3_bucket_id_parameter_name
    S3_BUCKET_REGION_PARAM = module.ssm.s3_bucket_region_parameter_name
  })
  
  tags = local.tags
}

# RDS Module - Primary Region
module "rds" {
  source = "../../modules/rds"
  
  environment            = var.environment
  region                 = var.region
  primary_region         = var.region
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
  db_multi_az            = false  # Disable Multi-AZ for high availability
  db_backup_retention_period = 7
  enable_cross_region_backup = false  # Disable cross-region backup for DR
  is_read_replica        = false
  
  tags = local.tags
}

# Load Balancer Module - Primary Region
module "load_balancer" {
  source = "../../modules/load_balancer"
  
  environment       = var.environment
  vpc_id            = module.vpc.vpc_id
  subnet_ids        = module.vpc.public_subnet_ids
  security_group_id = module.security_groups.lb_security_group_id
  
  tags = local.tags
}

# # Monitoring Module - Primary Region
# module "monitoring" {
#   source = "../../modules/monitoring"
  
#   environment = var.environment
#   region      = var.region
#   asg_name    = module.ec2.autoscaling_group_name
#   rds_primary_id = module.rds.primary_db_instance_id
#   rds_read_replica_id = null # No read replica in primary region
  
#   tags = local.tags
# }

# EventBridge rule to monitor AMI builder instance state
resource "aws_cloudwatch_event_rule" "ami_builder_state_change" {
  name        = "ami-builder-state-change"
  description = "Capture state changes for AMI builder instance"

  event_pattern = jsonencode({
    source      = ["aws.ec2"]
    detail-type = ["EC2 Instance State-change Notification"]
    detail      = {
      instance-id = [aws_instance.ami_builder.id]
      state       = ["terminated", "stopped"]
    }
  })
}

# EventBridge target to send events to DR region
resource "aws_cloudwatch_event_target" "send_to_dr_region" {
  rule      = aws_cloudwatch_event_rule.ami_builder_state_change.name
  target_id = "SendToDRRegion"
  arn       = "arn:aws:events:${var.dr_region}:${data.aws_caller_identity.current.account_id}:event-bus/default"
  role_arn  = module.iam.eventbridge_role_arn
}

# Add AWS caller identity data source
data "aws_caller_identity" "current" {}
