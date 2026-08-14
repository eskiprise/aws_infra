output "notifier_function_name" {
  value       = module.notifier.lambda_function_name
  description = "For CloudWatch log inspection if the notifier itself needs debugging"
}
