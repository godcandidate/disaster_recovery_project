# Global provider for Global Accelerator (must be us-east-1 or us-west-2)
provider "aws" {
  region = "us-east-1"
  alias  = "global"
}

# Primary region provider
provider "aws" {
  region = var.primary_region
  alias  = "primary"
}

# DR region provider
provider "aws" {
  region = var.dr_region
  alias  = "dr"
}

locals {
  tags = {
    Environment = var.environment
    Project     = "Disaster Recovery"
    ManagedBy   = "Terraform"
  }
}

# Remote state for primary environment
data "terraform_remote_state" "primary" {
  backend = "local"
  
  config = {
    path = "../primary/terraform.tfstate"
  }
}

# Remote state for DR environment
data "terraform_remote_state" "dr" {
  backend = "local"
  
  config = {
    path = "../dr/terraform.tfstate"
  }
}

# Primary region endpoint group (eu-west-1)
resource "aws_globalaccelerator_endpoint_group" "primary" {
  provider               = aws.global
  listener_arn          = aws_globalaccelerator_listener.app_listener.arn
  endpoint_group_region = var.primary_region
  health_check_path     = "/" # Health check endpoint
  health_check_port     = 80
  health_check_protocol = "HTTP"
  health_check_interval_seconds = 10
  threshold_count               = 2 # Fail faster with fewer checks

  endpoint_configuration {
    endpoint_id             = data.terraform_remote_state.primary.outputs.lb_arn
    #endpoint_id             = "arn:aws:elasticloadbalancing:eu-west-1:495599742316:loadbalancer/app/dr-alb-primary/ecd2cd5bb2c00dee"
    weight                  = 128 # Maximum weight for primary
    client_ip_preservation_enabled = true
  }

  # Keep this at 100 during normal operation
  traffic_dial_percentage = var.primary_traffic_dial_percentage
}

# DR region endpoint group (us-east-1)
resource "aws_globalaccelerator_endpoint_group" "dr" {
  provider               = aws.global
  listener_arn          = aws_globalaccelerator_listener.app_listener.arn
  endpoint_group_region = var.dr_region
  health_check_path     = "/" # Health check endpoint
  health_check_port     = 80
  health_check_protocol = "HTTP"
  health_check_interval_seconds = 10
  threshold_count               = 2 # Fail faster with fewer checks

  endpoint_configuration {
    endpoint_id             = data.terraform_remote_state.dr.outputs.lb_arn
    # endpoint_id             = "arn:aws:elasticloadbalancing:us-east-1:495599742316:loadbalancer/app/dr-alb-dr/d83b839f012558c6"
    weight                  = 20 # Equal weight for DR to ensure full traffic when primary fails
    client_ip_preservation_enabled = true
  }

  # Set to 100 so it's ready to receive traffic when primary fails
  # Global Accelerator will automatically route traffic here when primary is unhealthy
  traffic_dial_percentage = 0
}

# Global Accelerator must be created in us-east-1 or us-west-2
resource "aws_globalaccelerator_accelerator" "app_accelerator" {
  provider         = aws.global
  name            = "app-global-accelerator"
  ip_address_type = "IPV4"
  enabled         = true

  attributes {
    flow_logs_enabled   = false # Optional: Enable if you need flow logs
    flow_logs_s3_bucket = null
    flow_logs_s3_prefix = null
  }
  
  tags = local.tags
}

resource "aws_globalaccelerator_listener" "app_listener" {
  provider        = aws.global
  accelerator_arn = aws_globalaccelerator_accelerator.app_accelerator.arn
  protocol        = "TCP"
  port_range {
    from_port = 80
    to_port   = 80
  }
  
  # Enable client affinity to maintain session consistency during failover
  client_affinity = "SOURCE_IP"
}
