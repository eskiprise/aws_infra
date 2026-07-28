locals {
  # Isolated dev/test stage: its own bot token, its own admin chat, and the
  # dynamodb/ttrpg_club/dev tables — separate from prod's, so testing here can never
  # touch the real bot's data.
  dev_environment_variables = {
    TELEGRAM_TOKEN_SSM_PARAMETER = "/ttrpg_club/dev/poll_bot/token"
    ADMIN_CHAT_ID                = var.admin_chat_id
    TELEGRAM_RATING_POLLS_TABLE  = "ttrpg_club_dev_telegram_rating_polls"
    TELEGRAM_RATING_VOTES_TABLE  = "ttrpg_club_dev_telegram_rating_votes"
    MINI_APP_DEEP_LINK           = var.mini_app_deep_link
  }
}

resource "aws_iam_role" "lambda_role" {
  name = "telegram-poll-bot-dev-eu-west-2-lambdaRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "lambda.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    STAGE = "dev"
  }
}

resource "aws_iam_role_policy" "bot_permissions" {
  name = "telegram-poll-bot-dev-lambda"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["logs:CreateLogStream", "logs:CreateLogGroup"]
        Resource = [
          "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/telegram-poll-bot-dev*:*"
        ]
      },
      {
        Effect = "Allow"
        Action = ["logs:PutLogEvents"]
        Resource = [
          "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/telegram-poll-bot-dev*:*:*"
        ]
      },
      {
        Effect   = "Allow"
        Action   = ["ssm:GetParameter"]
        Resource = "arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:parameter/ttrpg_club/dev/poll_bot/token"
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetRecords",
          "dynamodb:GetShardIterator",
          "dynamodb:DescribeStream",
          "dynamodb:ListStreams",
        ]
        Resource = [
          data.aws_ssm_parameter.signup_requests_stream_arn_dev.value,
          data.aws_ssm_parameter.telegram_feedback_stream_arn_dev.value,
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
        ]
        Resource = "arn:aws:dynamodb:${var.region}:${data.aws_caller_identity.current.account_id}:table/ttrpg_club_dev_telegram_rating_polls"
      },
      {
        Effect   = "Allow"
        Action   = ["dynamodb:PutItem"]
        Resource = "arn:aws:dynamodb:${var.region}:${data.aws_caller_identity.current.account_id}:table/ttrpg_club_dev_telegram_rating_votes"
      },
    ]
  })
}

module "webhook" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "~> 8.0"

  function_name = "telegram-poll-bot-dev-webhook"
  description   = "Telegram Poll Bot (dev) — receives the webhook, handles commands and poll answers"
  handler       = "lambda_handler.lambda_handler"
  runtime       = "python3.14"
  timeout       = 30
  memory_size   = 256

  create_role                   = false
  lambda_role                   = aws_iam_role.lambda_role.arn
  attach_cloudwatch_logs_policy = false

  source_path = [
    {
      path             = "../../../ttrpg_poll_bot/build"
      pip_requirements = false
    }
  ]
  hash_extra = "webhook_dev"

  environment_variables = local.dev_environment_variables
}

module "notify_signup" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "~> 8.0"

  function_name = "telegram-poll-bot-dev-notifySignup"
  description   = "Telegram Poll Bot (dev) — DMs the admin chat about new club signup requests"
  handler       = "lambda_handler.notify_new_signup"
  runtime       = "python3.14"
  timeout       = 30
  memory_size   = 256

  create_role                   = false
  lambda_role                   = aws_iam_role.lambda_role.arn
  attach_cloudwatch_logs_policy = false

  source_path = [
    {
      path             = "../../../ttrpg_poll_bot/build"
      pip_requirements = false
    }
  ]
  hash_extra = "notify_signup_dev"

  environment_variables = local.dev_environment_variables
}

module "notify_feedback" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "~> 8.0"

  function_name = "telegram-poll-bot-dev-notifyFeedback"
  description   = "Telegram Poll Bot (dev) — DMs the GM when new session feedback is submitted"
  handler       = "lambda_handler.notify_new_feedback"
  runtime       = "python3.14"
  timeout       = 30
  memory_size   = 256

  create_role                   = false
  lambda_role                   = aws_iam_role.lambda_role.arn
  attach_cloudwatch_logs_policy = false

  source_path = [
    {
      path             = "../../../ttrpg_poll_bot/build"
      pip_requirements = false
    }
  ]
  hash_extra = "notify_feedback_dev"

  environment_variables = local.dev_environment_variables
}

# Fixed vs. the old combined module: these must point at the _dev-published stream ARNs
# (not _prod) — the IAM policy above only grants access to the dev streams, so wiring
# these to the prod stream ARNs would fail with access denied.
resource "aws_lambda_event_source_mapping" "notify_signup" {
  event_source_arn  = data.aws_ssm_parameter.signup_requests_stream_arn_dev.value
  function_name     = module.notify_signup.lambda_function_arn
  starting_position = "LATEST"
  batch_size        = 10

  tags = {
    STAGE = "dev"
  }
}

resource "aws_lambda_event_source_mapping" "notify_feedback" {
  event_source_arn  = data.aws_ssm_parameter.telegram_feedback_stream_arn_dev.value
  function_name     = module.notify_feedback.lambda_function_arn
  starting_position = "LATEST"
  batch_size        = 10

  tags = {
    STAGE = "dev"
  }
}

resource "aws_ssm_parameter" "ttrpg_dev" {
  for_each    = var.ttrpg_dev_params
  name        = each.key
  description = each.value
  type        = "SecureString"
  value       = "replace_me!"
  lifecycle {
    ignore_changes = [
      value
    ]
  }
}
