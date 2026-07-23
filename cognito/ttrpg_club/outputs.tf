output "user_pool_id" {
  value       = aws_cognito_user_pool.ttrpg_club.id
  sensitive   = false
  description = "Cognito User Pool ID (backend COGNITO_USER_POOL_ID / frontend VITE_COGNITO_USER_POOL_ID)"
}

output "user_pool_arn" {
  value       = aws_cognito_user_pool.ttrpg_club.arn
  sensitive   = false
  description = "Cognito User Pool ARN, used for the API Lambda's IAM policy"
}

output "web_client_id" {
  value       = aws_cognito_user_pool_client.web.id
  sensitive   = false
  description = "Cognito App Client ID (backend COGNITO_CLIENT_ID / frontend VITE_COGNITO_CLIENT_ID)"
}
