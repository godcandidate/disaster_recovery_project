output "global_accelerator_id" {
  description = "ID of the Global Accelerator"
  value       = aws_globalaccelerator_accelerator.app_accelerator.id
}

output "global_accelerator_dns_name" {
  description = "DNS name of the Global Accelerator"
  value       = aws_globalaccelerator_accelerator.app_accelerator.dns_name
}

output "global_accelerator_ip_sets" {
  description = "IP addresses of the Global Accelerator"
  value       = aws_globalaccelerator_accelerator.app_accelerator.ip_sets
}

output "primary_endpoint_group_id" {
  description = "ID of the primary endpoint group"
  value       = aws_globalaccelerator_endpoint_group.primary.id
}

output "dr_endpoint_group_id" {
  description = "ID of the DR endpoint group"
  value       = aws_globalaccelerator_endpoint_group.dr.id
}

output "primary_traffic_dial_percentage" {
  description = "Percentage of traffic routed to the primary region"
  value       = aws_globalaccelerator_endpoint_group.primary.traffic_dial_percentage
}

output "dr_traffic_dial_percentage" {
  description = "Percentage of traffic routed to the DR region"
  value       = aws_globalaccelerator_endpoint_group.dr.traffic_dial_percentage
}
