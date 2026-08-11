output "webhook_function_name" {
  value = module.webhook.lambda_function_name
}

output "scheduler_function_name" {
  value = module.scheduler.lambda_function_name
}

output "sender_function_name" {
  value = module.sender.lambda_function_name
}

output "webhook_url" {
  value       = "${aws_apigatewayv2_stage.default.invoke_url}webhook"
  description = "Register this with Telegram: python scripts/set_webhook.py <this url>"
}

output "daily_send_queue_url" {
  value = aws_sqs_queue.daily_send.url
}

output "daily_send_dlq_url" {
  value       = aws_sqs_queue.daily_send_dlq.url
  description = "Messages here mean the sender failed three times for that user — check before assuming delivery is healthy."
}
