output "lb_id" {
  description = "ID of the load balancer"
  value       = aws_lb.this.id
}

output "lb_arn" {
  description = "ARN of the load balancer"
  value       = aws_lb.this.arn
}

output "lb_dns_name" {
  description = "DNS name of the load balancer"
  value       = aws_lb.this.dns_name
}

output "target_group_arn" {
  description = "ARN of the target group"
  value       = aws_lb_target_group.this.arn
}

output "target_group_name" {
  description = "Name of the target group"
  value       = aws_lb_target_group.this.name
}
