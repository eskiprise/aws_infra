output "webhook_function_name" {
  value = module.webhook.lambda_function_name
}

output "notify_signup_function_name" {
  value = module.notify_signup.lambda_function_name
}

output "notify_feedback_function_name" {
  value = module.notify_feedback.lambda_function_name
}

output "webhook_url" {
  value       = "${aws_apigatewayv2_stage.default.invoke_url}webhook"
  description = "Register this as the dev/test bot's Telegram webhook (@BotFather /newbot)."
}
