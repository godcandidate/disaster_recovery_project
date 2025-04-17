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
  primary_region = var.region
  dr_region      = var.dr_region

  tags           = local.tags
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

# EC2 Module - Primary Region
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
  min_size             = 1
  max_size             = 3
  desired_capacity     = 1
  is_pilot_light       = false
  
  # User data script for EC2 instances
  user_data = templatefile("../../modules/templates/primary_userdata.tpl", {
    environment = var.environment
    region      = var.region
    DB_NAME     = var.db_name
    DB_USER     = var.db_username
    DB_PASSWORD = var.db_password
    DB_HOST     = module.rds.primary_db_instance_address
    EC2_IP      = "dummy" # This will be replaced at runtime by the script
  })
  
  tags = local.tags
}

# AMI Builder Instance - For creating a pre-configured AMI
resource "aws_instance" "ami_builder" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  subnet_id              = module.vpc.public_subnet_ids[0] # Use public subnet for easier access
  vpc_security_group_ids = [module.security_groups.ec2_security_group_id]
  key_name               = var.key_name
  iam_instance_profile   = module.iam.ec2_instance_profile_name
  
  user_data = templatefile("../../modules/templates/primary_userdata.tpl", {
    environment = var.environment
    region      = var.region
    DB_NAME     = var.db_name
    DB_USER     = var.db_username
    DB_PASSWORD = var.db_password
    DB_HOST     = module.rds.primary_db_instance_address
    EC2_IP      = "dummy" # This will be replaced at runtime by the script
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
  dr_region           = var.dr_region # Copy AMI to DR region
  
  tags = local.tags
  
  # Only create the AMI after the builder instance is fully provisioned
  depends_on = [aws_instance.ami_builder]
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
  db_multi_az            = false
  db_backup_retention_period = 7
  enable_cross_region_backup = false
  is_read_replica        = false
  
  tags = local.tags
}

# SSM Module removed as requested

# S3 Module - Primary Region with Cross-Region Replication to DR
module "s3" {
  source = "../../modules/s3"
  
  environment = var.environment
  region      = var.region
  dr_region   = var.dr_region
  bucket_name = "storage-${var.environment}"
  replication_role_arn = module.iam.s3_replication_role_arn
  
  providers = {
    aws    = aws
    aws.dr = aws.dr
  }
  
  tags = local.tags
}

# Lambda Module - Primary Region (Enabled)
module "lambda" {
  source = "../../modules/lambda"
  
  environment = var.environment
  region      = var.region
  function_name = "tasks-due-tomorrow"
  s3_bucket_id = module.s3.primary_bucket_id
  vpc_id      = module.vpc.vpc_id
  subnet_ids  = module.vpc.private_subnet_ids
  db_host     = module.rds.primary_db_instance_address
  db_username = var.db_username
  db_password = var.db_password
  db_name     = var.db_name
  enabled     = true  # Enabled in primary region
  build_locally = true
  lambda_role_arn = module.iam.lambda_role_arn
  
  tags = local.tags
  

}
