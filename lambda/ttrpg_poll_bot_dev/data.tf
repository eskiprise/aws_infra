data "aws_caller_identity" "current" {}

# Published by aws_infra's dynamodb/ttrpg_club/dev module — stream ARNs aren't
# deterministic (they carry a timestamp assigned when the stream is enabled, unlike a
# table ARN), so they're read here via SSM.
data "aws_ssm_parameter" "signup_requests_stream_arn_dev" {
  name = "/ttrpg_club/dev/signup_requests_stream_arn"
}

data "aws_ssm_parameter" "telegram_feedback_stream_arn_dev" {
  name = "/ttrpg_club/dev/telegram_feedback_stream_arn"
}
