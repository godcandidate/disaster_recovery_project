# Use local value for AMI name to prevent recreation on every apply
locals {
  # Use a fixed name based on environment and source instance ID
  ami_name = "dr-ami-${var.environment}-${substr(var.source_instance_id, -8, 8)}"
}

resource "aws_ami_from_instance" "this" {
  name               = local.ami_name
  source_instance_id = var.source_instance_id
  snapshot_without_reboot = var.snapshot_without_reboot

  tags = merge(
    {
      Name        = "dr-ami-${var.environment}"
      Environment = var.environment
      CreatedFrom = var.source_instance_id
    },
    var.tags
  )

  # Wait for AMI to be available
  timeouts {
    create = "20m"
    delete = "10m"
  }
  
  # Prevent recreation unless source instance ID changes
  lifecycle {
    ignore_changes = [name]
    create_before_destroy = true
  }
}

# Share AMI with target account if specified
resource "aws_ami_launch_permission" "share_ami" {
  count      = var.target_account_id != "" ? 1 : 0
  image_id   = aws_ami_from_instance.this.id
  account_id = var.target_account_id
}

# Copy AMI to DR region if specified
resource "aws_ami_copy" "dr_region" {
  provider          = aws.dr
  count             = var.dr_region != "" ? 1 : 0
  name              = "dr-ami-${var.environment}-copy-${substr(aws_ami_from_instance.this.id, -8, 8)}"
  source_ami_id     = aws_ami_from_instance.this.id
  source_ami_region = var.region
  encrypted         = true

  tags = merge(
    {
      Name        = "dr-ami-${var.environment}-copy"
      Environment = var.environment
      SourceAMI   = aws_ami_from_instance.this.id
    },
    var.tags
  )

  # Wait for AMI copy to be available
  timeouts {
    create = "15m"
    delete = "10m"
  }
  
  # Prevent recreation unless source AMI changes
  lifecycle {
    ignore_changes = [name]
    create_before_destroy = true
  }
}
