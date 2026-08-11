# Queue between the scheduler ("who is due right now") and the sender ("build
# and deliver one session"). It buys three things: retries with backoff when
# Telegram rate-limits us, a concurrency throttle via the sender's reserved
# concurrency, and a dead-letter queue so a permanently broken user doesn't
# spin forever.

resource "aws_sqs_queue" "daily_send_dlq" {
  name                      = "entutor-prod-daily-send-dlq"
  message_retention_seconds = 1209600 # 14 days — long enough to notice and debug

  tags = local.tags
}

resource "aws_sqs_queue" "daily_send" {
  name = "entutor-prod-daily-send"

  # Must be >= the sender's timeout, or SQS redelivers a message that is still
  # being processed and the user gets the session twice.
  visibility_timeout_seconds = 120
  message_retention_seconds  = 3600 # a stale daily nudge is worse than none

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.daily_send_dlq.arn
    maxReceiveCount     = 3
  })

  tags = local.tags
}

resource "aws_lambda_event_source_mapping" "sender" {
  event_source_arn = aws_sqs_queue.daily_send.arn
  function_name    = module.sender.lambda_function_arn

  # One user per invocation keeps a single bad record from failing a batch of
  # nine innocent ones.
  batch_size = 1

  # The handler returns batchItemFailures, so only genuinely failed records are
  # redelivered.
  function_response_types = ["ReportBatchItemFailures"]
}
