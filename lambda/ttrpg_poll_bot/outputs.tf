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

output "webhook_dev_function_name" {
  value = module.webhook_dev.lambda_function_name
}

output "notify_signup_dev_function_name" {
  value = module.notify_signup_dev.lambda_function_name
}

output "notify_feedback_dev_function_name" {
  value = module.notify_feedback_dev.lambda_function_name
}

output "webhook_dev_url" {
  value       = "${aws_apigatewayv2_stage.default.invoke_url}dev/webhook"
  description = "Register this as the second (dev/test) bot's Telegram webhook."
}
