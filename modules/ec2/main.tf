# Find the latest AMI if ami_id is not provided
data "aws_ami" "latest" {
  count       = var.ami_id == null ? 1 : 0
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
  ami_id = var.ami_id != null ? var.ami_id : data.aws_ami.latest[0].id
}

# Launch Template for EC2 instances
resource "aws_launch_template" "this" {
  name_prefix            = "dr-launch-template-${var.environment}-"
  image_id               = local.ami_id
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

  # For Pilot Light in DR region, we want the instances to be created but stopped
  suspended_processes = var.is_pilot_light && var.environment == "dr" ? [
    "Launch", "Terminate", "HealthCheck", "ReplaceUnhealthy", "AZRebalance", "AlarmNotification", "ScheduledActions", "AddToLoadBalancer"
  ] : []

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
  }

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

  lifecycle {
    create_before_destroy = true
  }
}

# If this is a Pilot Light setup in DR region, create a stopped EC2 instance
resource "aws_instance" "pilot_light" {
  count = var.is_pilot_light && var.environment == "dr" ? 1 : 0

  ami                    = local.ami_id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_ids[0]
  vpc_security_group_ids = [var.security_group_id]
  key_name               = var.key_name
  user_data              = var.user_data
  iam_instance_profile   = var.instance_profile_name

  # Instance is created in a stopped state
  instance_initiated_shutdown_behavior = "stop"

  tags = merge(
    {
      Name        = "dr-pilot-light-${var.environment}"
      Environment = var.environment
      PilotLight  = "true"
    },
    var.tags
  )

  # Ensure the instance is stopped after creation
  provisioner "local-exec" {
    command = "aws ec2 stop-instances --instance-ids ${self.id} --region ${var.region}"
  }

  lifecycle {
    ignore_changes = [ami]
  }
}
