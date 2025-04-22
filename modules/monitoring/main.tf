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

# CloudWatch Alarms for RDS
resource "aws_cloudwatch_metric_alarm" "rds_replica_lag" {
  alarm_name          = "dr-rds-replica-lag-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 5
  metric_name         = "ReplicaLag"
  namespace           = "AWS/RDS"
  period              = 60
  statistic           = "Average"
  threshold           = 300 # 5 minutes
  alarm_description   = "This metric monitors RDS replica lag"
  
  dimensions = {
    DBInstanceIdentifier = var.rds_read_replica_id
  }
  
  tags = merge(
    {
      Name        = "dr-rds-replica-lag-${var.environment}"
      Environment = var.environment
    },
    var.tags
  )
}

resource "aws_cloudwatch_metric_alarm" "rds_connections" {
  alarm_name          = "dr-rds-connections-${var.environment}"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 5
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = 60
  statistic           = "Average"
  threshold           = 1
  alarm_description   = "This metric monitors RDS database connections"
  
  dimensions = {
    DBInstanceIdentifier = var.rds_primary_id
  }
  
  tags = merge(
    {
      Name        = "dr-rds-connections-${var.environment}"
      Environment = var.environment
    },
    var.tags
  )
}

resource "aws_cloudwatch_metric_alarm" "rds_free_storage" {
  alarm_name          = "dr-rds-free-storage-${var.environment}"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 5
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = 60
  statistic           = "Average"
  threshold           = 5000000000 # 5 GB
  alarm_description   = "This metric monitors RDS free storage space"
  
  dimensions = {
    DBInstanceIdentifier = var.rds_primary_id
  }
  
  tags = merge(
    {
      Name        = "dr-rds-free-storage-${var.environment}"
      Environment = var.environment
    },
    var.tags
  )
}

# Composite Alarm for DR Failover
resource "aws_cloudwatch_composite_alarm" "dr_failover" {
  alarm_name        = "dr-failover-composite-alarm-${var.environment}"
  alarm_description = "Composite alarm for disaster recovery failover"
  
  alarm_rule = "(ALARM(${aws_cloudwatch_metric_alarm.ec2_system_check_failed.alarm_name}) OR ALARM(${aws_cloudwatch_metric_alarm.rds_replica_lag.alarm_name}))"
  
  alarm_actions = [var.sns_topic_arn]
  
  tags = merge(
    {
      Name        = "dr-failover-composite-alarm-${var.environment}"
      Environment = var.environment
    },
    var.tags
  )
}

# SNS Topic for Alarm Notifications
resource "aws_sns_topic" "dr_alarms" {
  name = "dr-alarms-${var.environment}"
  
  tags = merge(
    {
      Name        = "dr-alarms-${var.environment}"
      Environment = var.environment
    },
    var.tags
  )
}

# API Gateway integration removed as requested
