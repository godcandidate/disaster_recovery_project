output "ami_id" {
  description = "ID of the created AMI"
  value       = aws_ami_from_instance.this.id
}

output "ami_name" {
  description = "Name of the created AMI"
  value       = aws_ami_from_instance.this.name
}

output "ami_arn" {
  description = "ARN of the created AMI"
  value       = aws_ami_from_instance.this.arn
}

output "dr_region_ami_id" {
  description = "ID of the AMI copied to the DR region (if any)"
  value       = var.dr_region != "" ? aws_ami_copy.dr_region[0].id : null
}

output "dr_region_ami_name" {
  description = "Name of the AMI copied to the DR region (if any)"
  value       = var.dr_region != "" ? aws_ami_copy.dr_region[0].name : null
}

output "dr_region_ami_arn" {
  description = "ARN of the AMI copied to the DR region (if any)"
  value       = var.dr_region != "" ? aws_ami_copy.dr_region[0].arn : null
}
