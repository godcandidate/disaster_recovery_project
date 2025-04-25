# Monitoring Module for Disaster Recovery

# CloudWatch Alarms for EC2 Instances
resource "aws_cloudwatch_metric_alarm" "ec2_system_check_failed" {
  alarm_name          = "dr-ec2-system-check-failed-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 5
  metric_name         = "StatusCheckFailed_System"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Maximum"
  threshold           = 0
  alarm_description   = "This metric monitors EC2 system status checks (hardware/region level issues)"
  
  dimensions = {
    AutoScalingGroupName = var.asg_name
  }
  
  tags = merge(
    {
      Name        = "dr-ec2-system-check-failed-${var.environment}"
      Environment = var.environment
    },
    var.tags
  )
}

resource "aws_cloudwatch_metric_alarm" "ec2_instance_check_failed" {
  alarm_name          = "dr-ec2-instance-check-failed-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 5
  metric_name         = "StatusCheckFailed_Instance"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Maximum"
  threshold           = 0
  alarm_description   = "This metric monitors EC2 instance status checks (instance-specific failures)"
  
  dimensions = {
    AutoScalingGroupName = var.asg_name
  }
  
  tags = merge(
    {
      Name        = "dr-ec2-instance-check-failed-${var.environment}"
      Environment = var.environment
    },
    var.tags
  )
}

resource "aws_cloudwatch_metric_alarm" "ec2_instance_state" {
  alarm_name          = "dr-ec2-instance-state-${var.environment}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 3
  metric_name         = "GroupInServiceInstances"
  namespace           = "AWS/AutoScaling"
  period              = 60
  statistic           = "Minimum"
  threshold           = 1
  alarm_description   = "This metric monitors the number of EC2 instances in service"
  
  dimensions = {
    AutoScalingGroupName = var.asg_name
  }
  
  tags = merge(
    {
      Name        = "dr-ec2-instance-state-${var.environment}"
      Environment = var.environment
    },
    var.tags
  )
}






