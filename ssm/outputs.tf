output "parameters_arn" {
  value       = { for p in aws_ssm_parameter.param : p.name => p.arn }
  sensitive   = false
  description = "ARN SSM params"
  depends_on  = [aws_ssm_parameter.param]
}
