# The scheduler runs every hour rather than once a day at 14:00 UTC, because
# users pick their own timezone. Each run keeps only the users whose *local*
# clock currently reads SEND_HOUR — so 14:00 means 14:00 in Kyiv, Berlin or
# Toronto without a rule per zone.

resource "aws_cloudwatch_event_rule" "hourly" {
  name                = "entutor-prod-hourly-scheduler"
  description         = "Fires every hour; the Lambda filters to users at their local send hour"
  schedule_expression = "cron(0 * * * ? *)"

  tags = local.tags
}

resource "aws_cloudwatch_event_target" "scheduler" {
  rule      = aws_cloudwatch_event_rule.hourly.name
  target_id = "entutor-prod-scheduler"
  arn       = module.scheduler.lambda_function_arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = module.scheduler.lambda_function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.hourly.arn
}
