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
  description = "The live bot's registered Telegram webhook URL — must stay byte-identical across the state-split migration."
}
