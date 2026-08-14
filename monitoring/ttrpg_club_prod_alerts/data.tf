data "aws_caller_identity" "current" {}

# The 4 prod log groups to watch — deliberately prod-only. Dev is under active
# development/testing and naturally produces expected errors (e.g. while iterating on a
# bug fix), which would make a dev alert noisy and easy to tune out; prod errors are
# always actionable. These log groups already exist (created by each function's own
# Terraform module via the terraform-aws-modules/lambda/aws module's
# attach_cloudwatch_logs_policy/log group resource) — looked up by name rather than
# coupled via remote state, since the name is fully deterministic.
locals {
  monitored_functions = [
    "ttrpg-club-api-prod",
    "telegram-poll-bot-prod-webhook",
    "telegram-poll-bot-prod-notifySignup",
    "telegram-poll-bot-prod-notifyFeedback",
  ]
}

data "aws_cloudwatch_log_group" "monitored" {
  for_each = toset(local.monitored_functions)
  name     = "/aws/lambda/${each.value}"
}
