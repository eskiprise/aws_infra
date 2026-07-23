output "parameters_arn" {
  value       = { for p in aws_ssm_parameter.param : p.name => p.arn }
  sensitive   = false
  description = "ARN of each SSM parameter, by name"
  depends_on  = [aws_ssm_parameter.param]
}
