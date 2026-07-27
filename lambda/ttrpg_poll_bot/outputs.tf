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
  description = "Must be byte-identical to the URL already registered as this bot's Telegram webhook — if it differs after import, something is wrong before you retire the old stack."
}
