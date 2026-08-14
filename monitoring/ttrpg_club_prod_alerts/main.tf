# Cheapest correct shape for "tell me on Telegram if prod errors": CloudWatch Logs
# subscription filters push matching log lines directly to a Lambda — no CloudWatch
# Alarms, no custom metrics, no SNS topic. That combination would cost ~$0.10/alarm/
# month flat (regardless of whether it ever fires) plus up to ~$0.30/metric/month in
# any hour an error actually occurs; a subscription filter straight to Lambda has no
# per-metric or per-alarm charge at all — you only pay for the (essentially free at
# this volume) Lambda invocations, which only happen when there's actually an error to
# report. The tradeoff: no OK/ALARM-state deduplication, so a sustained flood of errors
# means a steady stream of digests rather than one "still broken" ping — acceptable
# (arguably correct) for "alert me on every error" at hobby-project error volumes.

module "notifier" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "~> 8.0"

  function_name = "ttrpg-club-prod-error-notifier"
  description   = "Forwards ERROR-level log lines from ttrpg_club prod Lambdas to Telegram"
  handler       = "handler.lambda_handler"
  runtime       = "python3.14"
  timeout       = 10
  memory_size   = 128

  attach_cloudwatch_logs_policy = true

  source_path = [
    {
      path             = "${path.module}/notifier"
      pip_requirements = false
    }
  ]

  environment_variables = {
    # The live prod poll bot's own token — this is purely an ops notification, not a
    # user-facing bot feature, so it doesn't warrant registering a separate bot.
    BOT_TOKEN_SSM_PARAMETER = "/ttrpg_club/prod/poll_bot/token"
    ADMIN_CHAT_ID           = var.admin_chat_id
  }

  attach_policy_statements = true
  policy_statements = {
    read_bot_token = {
      effect    = "Allow"
      actions   = ["ssm:GetParameter"]
      resources = ["arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:parameter/ttrpg_club/prod/poll_bot/token"]
    }
  }
}

resource "aws_lambda_permission" "allow_cloudwatch" {
  for_each      = data.aws_cloudwatch_log_group.monitored
  statement_id  = "AllowCloudWatchLogs-${each.key}"
  action        = "lambda:InvokeFunction"
  function_name = module.notifier.lambda_function_name
  principal     = "logs.${var.region}.amazonaws.com"
  source_arn    = "${each.value.arn}:*"
}

resource "aws_cloudwatch_log_subscription_filter" "errors" {
  for_each = data.aws_cloudwatch_log_group.monitored

  name            = "ttrpg-club-prod-error-alert"
  log_group_name  = each.value.name
  filter_pattern  = "{ $.level = \"ERROR\" }"
  destination_arn = module.notifier.lambda_function_arn

  depends_on = [aws_lambda_permission.allow_cloudwatch]
}
