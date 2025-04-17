output "launch_template_id" {
  description = "ID of the launch template"
  value       = aws_launch_template.this.id
}

output "launch_template_version" {
  description = "Latest version of the launch template"
  value       = aws_launch_template.this.latest_version
}

output "autoscaling_group_id" {
  description = "ID of the Auto Scaling group"
  value       = aws_autoscaling_group.this.id
}

output "autoscaling_group_name" {
  description = "Name of the Auto Scaling group"
  value       = aws_autoscaling_group.this.name
}

output "ami_id" {
  description = "AMI ID used for EC2 instances"
  value       = local.ami_id
}

output "pilot_light_instance_id" {
  description = "ID of the pilot light instance in DR region"
  value       = var.is_pilot_light && var.environment == "dr" ? aws_instance.pilot_light[0].id : null
}

# AMI builder functionality moved to standalone EC2 instance in primary environment
