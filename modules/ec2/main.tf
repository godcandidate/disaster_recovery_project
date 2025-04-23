# Find the latest AMI if ami_id is not provided
data "aws_ami" "latest" {
  most_recent = true
  owners      = var.ami_owners

  filter {
    name   = "name"
    values = [var.ami_filter["name"]]
  }

  filter {
    name   = "virtualization-type"
    values = [var.ami_filter["virtualization-type"]]
  }

  filter {
    name   = "root-device-type"
    values = [var.ami_filter["root-device-type"]]
  }
}

locals {
  ami_id = coalesce(var.ami_id, data.aws_ami.latest.id)
}

# Launch Template for EC2 instances
resource "aws_launch_template" "this" {
  name_prefix            = "dr-launch-template-${var.environment}-"
  image_id               = var.ami_id != "" ? var.ami_id : local.ami_id
  instance_type          = var.instance_type
  vpc_security_group_ids = [var.security_group_id]
  key_name               = var.key_name
  user_data              = var.user_data != "" ? base64encode(var.user_data) : null

  iam_instance_profile {
    name = var.instance_profile_name
  }

  monitoring {
    enabled = true
  }

  tag_specifications {
    resource_type = "instance"
    tags = merge(
      {
        Name        = "dr-instance-${var.environment}"
        Environment = var.environment
      },
      var.tags
    )
  }

  tag_specifications {
    resource_type = "volume"
    tags = merge(
      {
        Name        = "dr-volume-${var.environment}"
        Environment = var.environment
      },
      var.tags
    )
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "this" {
  name_prefix         = "dr-asg-${var.environment}-"
  vpc_zone_identifier = var.subnet_ids
  min_size            = var.min_size
  max_size            = var.max_size
  desired_capacity    = var.desired_capacity

  launch_template {
    id      = aws_launch_template.this.id
    version = "$Latest"
  }

  # We no longer suspend processes since we're using ASG-based failover
  # The ASG will have desired capacity = 0 during normal operation
  # and will be scaled up by the Lambda function during failover
  suspended_processes = []

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
  }
  
  # Health check settings
  health_check_type         = "EC2"
  health_check_grace_period = 300

  dynamic "tag" {
    for_each = merge(
      {
        Name        = "dr-asg-${var.environment}"
        Environment = var.environment
      },
      var.tags
    )
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  target_group_arns = var.target_group_arns

  lifecycle {
    create_before_destroy = true
  }
}

# AMI builder functionality moved to standalone EC2 instance in primary environment
