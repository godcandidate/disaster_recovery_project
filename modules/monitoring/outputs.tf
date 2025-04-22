output "ec2_system_check_alarm_arn" {
  description = "ARN of the EC2 system check alarm"
  value       = aws_cloudwatch_metric_alarm.ec2_system_check_failed.arn
}

output "ec2_instance_check_alarm_arn" {
  description = "ARN of the EC2 instance check alarm"
  value       = aws_cloudwatch_metric_alarm.ec2_instance_check_failed.arn
}

output "ec2_instance_state_alarm_arn" {
  description = "ARN of the EC2 instance state alarm"
  value       = aws_cloudwatch_metric_alarm.ec2_instance_state.arn
}

output "rds_replica_lag_alarm_arn" {
  description = "ARN of the RDS replica lag alarm"
  value       = aws_cloudwatch_metric_alarm.rds_replica_lag.arn
}

output "rds_connections_alarm_arn" {
  description = "ARN of the RDS connections alarm"
  value       = aws_cloudwatch_metric_alarm.rds_connections.arn
}

output "rds_free_storage_alarm_arn" {
  description = "ARN of the RDS free storage alarm"
  value       = aws_cloudwatch_metric_alarm.rds_free_storage.arn
}

output "composite_alarm_arn" {
  description = "ARN of the composite alarm"
  value       = aws_cloudwatch_composite_alarm.dr_failover.arn
}

output "sns_topic_arn" {
  description = "ARN of the SNS topic for alarm notifications"
  value       = aws_sns_topic.dr_alarms.arn
}
