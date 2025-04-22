output "step_function_arn" {
  description = "ARN of the Step Function state machine"
  value       = aws_sfn_state_machine.dr_failover.arn
}

output "step_function_name" {
  description = "Name of the Step Function state machine"
  value       = aws_sfn_state_machine.dr_failover.name
}

output "step_function_role_arn" {
  description = "ARN of the IAM role for the Step Function"
  value       = aws_iam_role.step_function.arn
}
