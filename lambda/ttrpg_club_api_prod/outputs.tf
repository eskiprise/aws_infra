output "api_base_url" {
  value       = aws_apigatewayv2_stage.default.invoke_url
  sensitive   = false
  description = "Base URL for the frontend's VITE_API_BASE_URL"
  depends_on  = [aws_apigatewayv2_stage.default]
}

output "lambda_function_name" {
  value       = module.lambda_function.lambda_function_name
  sensitive   = false
  description = "API Lambda function name"
  depends_on  = [module.lambda_function]
}
