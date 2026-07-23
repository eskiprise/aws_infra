output "lambda_function_name" {
  value       = module.lambda_function.lambda_function_name
  sensitive   = false
  description = "Notifier Lambda function name"
  depends_on  = [module.lambda_function]
}
