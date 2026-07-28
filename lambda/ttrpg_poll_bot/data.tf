data "aws_caller_identity" "current" {}

# Published by aws_infra's dynamodb/ttrpg_club/dev module — stream ARNs aren't
# deterministic (they carry a timestamp assigned when the stream is enabled, unlike a
# table ARN), so they're read here the same way ttrpg_poll_bot's old serverless.yml did
# via ${ssm:...}.
data "aws_ssm_parameter" "signup_requests_stream_arn_dev" {
  name = "/ttrpg_club/dev/signup_requests_stream_arn"
}

data "aws_ssm_parameter" "telegram_feedback_stream_arn_dev" {
  name = "/ttrpg_club/dev/telegram_feedback_stream_arn"
}

# Same two streams, but published by dynamodb/ttrpg_club/prod — used only by the dev
# stage below. The prod-named (real, live) functions above deliberately keep reading the
# dev-published ARNs; only the new dev stage points at the (currently empty) prod tables,
# for isolated testing.
data "aws_ssm_parameter" "signup_requests_stream_arn_prod" {
  name = "/ttrpg_club/prod/signup_requests_stream_arn"
}

data "aws_ssm_parameter" "telegram_feedback_stream_arn_prod" {
  name = "/ttrpg_club/prod/telegram_feedback_stream_arn"
}
